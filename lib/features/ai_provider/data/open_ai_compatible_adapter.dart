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
  /// search variants.
  OpenAiCompatibleAdapter.openAi(http.Client client)
      : this._(client, Uri.parse('https://api.openai.com/v1/'), _openAiChat);

  /// Groq: every model but Whisper (speech to text) and the Guard
  /// classifiers.
  OpenAiCompatibleAdapter.groq(http.Client client)
      : this._(client, Uri.parse('https://api.groq.com/openai/v1/'), _groqChat);

  /// Ends with a slash so relative paths resolve under it.
  final Uri _baseUrl;

  /// Whether a model id from `/models` can answer a chat.
  final bool Function(String id) _isChatModel;

  final http.Client _http;

  static bool _openAiChat(String id) =>
      (id.startsWith('gpt-') || RegExp(r'^o\d').hasMatch(id)) &&
      !const ['audio', 'realtime', 'image', 'transcribe', 'tts', 'search'].any(id.contains);

  static bool _groqChat(String id) => !id.contains('whisper') && !id.contains('guard');

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

  @override
  Future<void> ping(String apiKey, String model) => providerRequest(
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
