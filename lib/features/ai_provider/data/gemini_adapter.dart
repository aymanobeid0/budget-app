import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../consultant/models/chat_message.dart';
import '../models/ai_provider.dart';
import 'provider_adapter.dart';
import 'provider_http.dart';

/// Google Gemini over its REST API (`generativelanguage.googleapis.com`).
class GeminiAdapter implements ProviderAdapter {
  GeminiAdapter(this._http);

  static final _base = Uri.parse('https://generativelanguage.googleapis.com/v1beta/');

  final http.Client _http;

  Map<String, String> _headers(String apiKey) => {'x-goog-api-key': apiKey};

  @override
  Future<List<String>> listModels(String apiKey) async {
    final response = await providerRequest(
      () => _http.get(_base.resolve('models?pageSize=1000'), headers: _headers(apiKey)),
      classify: _classify,
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final models = <String>[
      for (final m in (body['models'] as List? ?? const []).cast<Map<String, dynamic>>())
        if ((m['supportedGenerationMethods'] as List? ?? const []).contains('generateContent'))
          (m['name'] as String).replaceFirst('models/', ''),
    ]..removeWhere(_notForChat);
    return models..sort();
  }

  /// Gemini answers a bad key with 400 rather than 401.
  static ConnectionOutcome _classify(int statusCode, Map<String, dynamic>? error) {
    final details = (error?['details'] as List? ?? const []).whereType<Map<String, dynamic>>();
    if (details.any((d) => d['reason'] == 'API_KEY_INVALID')) return ConnectionOutcome.keyNotAccepted;
    return ConnectionOutcome.fromStatusCode(statusCode);
  }

  /// Speech and image models also answer generateContent but can't chat.
  static bool _notForChat(String id) => id.contains('tts') || id.contains('image') || id.contains('embedding');

  @override
  Future<void> ping(String apiKey, String model) => providerRequest(
        () => _http.post(
          _base.resolve('models/$model:generateContent'),
          headers: {..._headers(apiKey), 'content-type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'role': 'user', 'parts': [{'text': 'ping'}]},
            ],
            'generationConfig': {'maxOutputTokens': 1},
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
    final request = http.Request('POST', _base.resolve('models/$model:streamGenerateContent?alt=sse'))
      ..headers.addAll({..._headers(apiKey), 'content-type': 'application/json'})
      ..body = jsonEncode({
        'systemInstruction': {'parts': [{'text': systemInstruction}]},
        'contents': [
          for (final m in history) _content(m.isUser ? 'user' : 'model', m.text),
          _content('user', prompt),
        ],
      });
    await for (final data in providerStream(_http, request, classify: _classify)) {
      final event = decodeEvent(data);
      final candidates = (event['candidates'] as List? ?? const []).cast<Map<String, dynamic>>();
      final parts = candidates.isEmpty ? const [] : (candidates.first['content']?['parts'] as List? ?? const []);
      for (final part in parts.cast<Map<String, dynamic>>()) {
        final text = part['text'] as String?;
        if (text != null && text.isNotEmpty) yield text;
      }
    }
  }

  static Map<String, dynamic> _content(String role, String text) => {
        'role': role,
        'parts': [{'text': text}],
      };
}
