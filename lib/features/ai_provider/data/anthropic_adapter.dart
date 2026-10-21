import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../consultant/models/chat_message.dart';
import '../models/ai_provider.dart';
import 'provider_adapter.dart';
import 'provider_http.dart';

/// Anthropic Claude over its own REST API: `x-api-key` auth, `/v1/models`
/// and streaming `/v1/messages`.
class AnthropicAdapter implements ProviderAdapter {
  AnthropicAdapter(this._http);

  static final _baseUrl = Uri.parse('https://api.anthropic.com/v1/');

  /// Anthropic requires a reply cap. Room for a long answer, plus thinking
  /// on models that think by default.
  static const _maxReplyTokens = 8192;

  final http.Client _http;

  Map<String, String> _headers(String apiKey) => {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'};

  Map<String, String> _jsonHeaders(String apiKey) => {..._headers(apiKey), 'content-type': 'application/json'};

  /// Anthropic answers an empty credit balance with 400, not 402. Overloaded
  /// (529) falls through to Provider error.
  static ConnectionOutcome _classify(int statusCode, Map<String, dynamic>? error) {
    final message = error?['message'] as String? ?? '';
    if (message.contains('credit balance')) return ConnectionOutcome.noCredit;
    return ConnectionOutcome.fromStatusCode(statusCode);
  }

  /// An `error` event mid-stream arrives after the 200, so its type stands
  /// in for the status Anthropic gives that error up front.
  static const _statusForErrorType = {
    'invalid_request_error': 400,
    'authentication_error': 401,
    'billing_error': 402,
    'permission_error': 403,
    'not_found_error': 404,
    'rate_limit_error': 429,
    'api_error': 500,
    'overloaded_error': 529,
  };

  /// Every Anthropic model can chat, so nothing is filtered out. One page
  /// of 1000 holds them all.
  @override
  Future<List<String>> listModels(String apiKey) async {
    final response = await providerRequest(
      () => _http.get(_baseUrl.resolve('models?limit=1000'), headers: _headers(apiKey)),
      classify: _classify,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final m in (body['data'] as List? ?? const []).cast<Map<String, dynamic>>()) m['id'] as String,
    ]..sort();
  }

  @override
  Future<void> ping(String apiKey, String model) => providerRequest(
        () => _http.post(
          _baseUrl.resolve('messages'),
          headers: _jsonHeaders(apiKey),
          body: jsonEncode({
            'model': model,
            'max_tokens': 1,
            'messages': [{'role': 'user', 'content': 'ping'}],
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
    final request = http.Request('POST', _baseUrl.resolve('messages'))
      ..headers.addAll(_jsonHeaders(apiKey))
      ..body = jsonEncode({
        'model': model,
        'max_tokens': _maxReplyTokens,
        'stream': true,
        'system': systemInstruction,
        'messages': [
          for (final m in history) {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          {'role': 'user', 'content': prompt},
        ],
      });
    await for (final data in providerStream(_http, request, classify: _classify)) {
      final event = decodeEvent(data);
      switch (event['type']) {
        case 'content_block_delta':
          final delta = event['delta'] as Map<String, dynamic>?;
          final text = delta?['type'] == 'text_delta' ? delta!['text'] as String? : null;
          if (text != null && text.isNotEmpty) yield text;
        case 'error':
          final error = event['error'] as Map<String, dynamic>?;
          throw ProviderFailure(
            _classify(_statusForErrorType[error?['type']] ?? 500, error),
            error?['message'] as String? ?? '',
          );
        case 'message_stop':
          return;
      }
    }
  }
}
