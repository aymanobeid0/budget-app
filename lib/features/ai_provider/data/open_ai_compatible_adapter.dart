import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../consultant/models/chat_message.dart';
import '../models/ai_provider.dart';
import 'provider_adapter.dart';
import 'provider_http.dart';

/// A provider that speaks OpenAI's REST API (`/models`, `/chat/completions`)
/// with Bearer auth. Each provider has its own base URL and its own rule for
/// which of its models can chat.
class OpenAiCompatibleAdapter implements ProviderAdapter {
  OpenAiCompatibleAdapter._(this._http, this._baseUrl, this._isChatModel);

  /// OpenAI: the `gpt-*` and o-series models, minus speech, image and
  /// search variants and the models `/chat/completions` can't serve.
  OpenAiCompatibleAdapter.openAi(http.Client client)
      : this._(client, Uri.parse('https://api.openai.com/v1/'), _openAiChat);

  /// Groq: every model but Whisper (speech to text), text to speech and the
  /// Guard classifiers.
  OpenAiCompatibleAdapter.groq(http.Client client)
      : this._(client, Uri.parse('https://api.groq.com/openai/v1/'), _groqChat);

  /// Ends with a slash so relative paths resolve under it.
  final Uri _baseUrl;

  /// Whether a model id from `/models` can answer a chat.
  final bool Function(String id) _isChatModel;

  final http.Client _http;

  static bool _openAiChat(String id) =>
      (id.startsWith('gpt-') || RegExp(r'^o\d').hasMatch(id)) &&
      !const ['audio', 'realtime', 'image', 'transcribe', 'tts', 'search', 'instruct', '-pro', 'deep-research'].any(id.contains);

  static bool _groqChat(String id) => !const ['whisper', 'guard', 'tts'].any(id.contains);

  Map<String, String> _headers(String apiKey) => {'authorization': 'Bearer $apiKey'};

  Map<String, String> _jsonHeaders(String apiKey) => {..._headers(apiKey), 'content-type': 'application/json'};

  /// Groq answers a retired model with 400 rather than 404.
  static ConnectionOutcome _classify(int statusCode, Map<String, dynamic>? error) =>
      switch (error?['code']) {
        'model_not_found' || 'model_decommissioned' => ConnectionOutcome.modelNotFound,
        _ => ConnectionOutcome.fromStatusCode(statusCode),
      };

  @override
  Future<List<String>> listModels(String apiKey) async {
    final response = await providerRequest(
      () => _http.get(_baseUrl.resolve('models'), headers: _headers(apiKey)),
      classify: _classify,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final m in (body['data'] as List? ?? const []).cast<Map<String, dynamic>>())
        if (_isChatModel(m['id'] as String)) m['id'] as String,
    ]..sort();
  }

  /// A reasoning model spends its one token thinking and reports the limit
  /// as an error, though it proved the key, model and credit all work.
  static bool _ranOutOfTokens(ProviderFailure failure) =>
      failure.outcome == ConnectionOutcome.providerError && failure.message.contains('max_tokens or model output limit');

  @override
  Future<void> ping(String apiKey, String model) async {
    try {
      await providerRequest(
        () => _http.post(
          _baseUrl.resolve('chat/completions'),
          headers: _jsonHeaders(apiKey),
          body: jsonEncode({
            'model': model,
            'messages': [{'role': 'user', 'content': 'ping'}],
            'max_completion_tokens': 1,
          }),
        ),
        classify: _classify,
      );
    } on ProviderFailure catch (failure) {
      if (!_ranOutOfTokens(failure)) rethrow;
    }
  }

  @override
  Stream<String> streamReply({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<ChatMessage> history,
    required String prompt,
  }) async* {
    final request = http.Request('POST', _baseUrl.resolve('chat/completions'))
      ..headers.addAll(_jsonHeaders(apiKey))
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': systemInstruction},
          for (final m in history) {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          {'role': 'user', 'content': prompt},
        ],
      });
    await for (final data in providerStream(_http, request, classify: _classify)) {
      if (data == '[DONE]') return;
      final event = jsonDecode(data) as Map<String, dynamic>;
      final choices = (event['choices'] as List? ?? const []).cast<Map<String, dynamic>>();
      final text = choices.isEmpty ? null : choices.first['delta']?['content'] as String?;
      if (text != null && text.isNotEmpty) yield text;
    }
  }
}

/// OpenRouter: chats as OpenAI does, but its `/models` list is public and
/// too long to pick from, so the user types a model id. Test checks the key
/// with `GET /key`, then looks the typed id up in `/models`.
class OpenRouterAdapter extends OpenAiCompatibleAdapter implements TypedModelAdapter {
  OpenRouterAdapter(http.Client client) : super._(client, Uri.parse('https://openrouter.ai/api/v1/'), _anyModel);

  static bool _anyModel(String id) => true;

  /// Checks the key with `GET /key`, then lists every model.
  @override
  Future<List<String>> listModels(String apiKey) async {
    await providerRequest(
      () => _http.get(_baseUrl.resolve('key'), headers: _headers(apiKey)),
      classify: OpenAiCompatibleAdapter._classify,
    );
    return super.listModels(apiKey);
  }

  @override
  Future<void> testModel(String apiKey, String model) async {
    final models = await listModels(apiKey);
    if (!models.contains(model)) {
      throw ProviderFailure(ConnectionOutcome.modelNotFound, '"$model" isn\'t an OpenRouter model id. Copy one from openrouter.ai/models.');
    }
  }
}
