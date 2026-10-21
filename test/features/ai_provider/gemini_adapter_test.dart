import 'dart:async';
import 'dart:convert';

import 'package:budget_app/features/ai_provider/data/gemini_adapter.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('listModels', () {
    test('lists only chat models, by id, and sends the key in a header', () async {
      http.Request? sent;
      final adapter = GeminiAdapter(MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'models/gemini-2.5-pro', 'supportedGenerationMethods': ['generateContent', 'countTokens']},
              {'name': 'models/text-embedding-004', 'supportedGenerationMethods': ['embedContent']},
              {'name': 'models/gemini-2.5-flash', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/gemini-2.5-flash-preview-tts', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/gemini-2.5-flash-image', 'supportedGenerationMethods': ['generateContent']},
            ],
          }),
          200,
        );
      }));

      final models = await adapter.listModels('key-123');

      expect(models, ['gemini-2.5-flash', 'gemini-2.5-pro']);
      expect(sent!.headers['x-goog-api-key'], 'key-123');
      expect(sent!.url.queryParameters.containsKey('key'), isFalse);
    });

    test("a rejected key is 'Key not accepted' with Google's message, though Gemini answers 400", () async {
      final adapter = GeminiAdapter(MockClient((_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 400,
                'message': 'API key not valid. Please pass a valid API key.',
                'status': 'INVALID_ARGUMENT',
                'details': [
                  {'@type': 'type.googleapis.com/google.rpc.ErrorInfo', 'reason': 'API_KEY_INVALID'},
                ],
              },
            }),
            400,
          )));

      expect(
        adapter.listModels('bad'),
        throwsA(isA<ProviderFailure>()
            .having((f) => f.outcome, 'outcome', ConnectionOutcome.keyNotAccepted)
            .having((f) => f.message, 'message', 'API key not valid. Please pass a valid API key.')),
      );
    });

    test("a used-up quota is 'No credit or rate-limited'", () async {
      final adapter = GeminiAdapter(MockClient((_) async => http.Response(
            jsonEncode({'error': {'code': 429, 'message': 'Quota exceeded', 'status': 'RESOURCE_EXHAUSTED'}}),
            429,
          )));

      expect(adapter.listModels('k'), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.noCredit)));
    });

    test("no connection is \"Can't reach provider\"", () async {
      final adapter = GeminiAdapter(MockClient((_) async => throw http.ClientException('Failed host lookup')));

      expect(adapter.listModels('k'), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.unreachable)));
    });

    test('a 5xx with a non-JSON body is a Provider error carrying the body', () async {
      final adapter = GeminiAdapter(MockClient((_) async => http.Response('upstream down', 503)));

      expect(
        adapter.listModels('k'),
        throwsA(isA<ProviderFailure>()
            .having((f) => f.outcome, 'outcome', ConnectionOutcome.providerError)
            .having((f) => f.message, 'message', 'upstream down')),
      );
    });
  });

  group('ping', () {
    test('asks the chosen model for a single token', () async {
      http.Request? sent;
      final adapter = GeminiAdapter(MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'candidates': []}), 200);
      }));

      await adapter.ping('key-123', 'gemini-2.5-flash');

      expect(sent!.method, 'POST');
      expect(sent!.url.path, '/v1beta/models/gemini-2.5-flash:generateContent');
      expect(sent!.headers['x-goog-api-key'], 'key-123');
      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      expect(body['generationConfig'], {'maxOutputTokens': 1});
    });

    test("an unknown model is 'Model not found'", () async {
      final adapter = GeminiAdapter(MockClient((_) async => http.Response(
            jsonEncode({'error': {'code': 404, 'message': 'models/nope is not found', 'status': 'NOT_FOUND'}}),
            404,
          )));

      expect(adapter.ping('k', 'nope'), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.modelNotFound)));
    });
  });

  group('streamReply', () {
    String event(String text) => 'data: ${jsonEncode({
          'candidates': [
            {'content': {'role': 'model', 'parts': [{'text': text}]}},
          ],
        })}\r\n\r\n';

    test('yields each text part and sends the system prompt and history as Gemini contents', () async {
      http.BaseRequest? sent;
      String? sentBody;
      final whole = event('You spent ') + event('most on Food.');
      final split = whole.length ~/ 2; // an event cut across two network chunks
      final adapter = GeminiAdapter(MockClient.streaming((request, bodyStream) async {
        sent = request;
        sentBody = await bodyStream.bytesToString();
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode(whole.substring(0, split)), utf8.encode(whole.substring(split))]),
          200,
        );
      }));

      final chunks = await adapter
          .streamReply(
            apiKey: 'key-123',
            model: 'gemini-2.5-flash',
            systemInstruction: 'Be brief.',
            history: [
              ChatMessage(id: 'u1', text: 'Hi', isUser: true, timestamp: DateTime(2026)),
              ChatMessage(id: 'a1', text: 'Hello!', isUser: false, timestamp: DateTime(2026)),
            ],
            prompt: 'Where did my money go?',
          )
          .toList();

      expect(chunks, ['You spent ', 'most on Food.']);
      expect(sent!.url.path, '/v1beta/models/gemini-2.5-flash:streamGenerateContent');
      expect(sent!.url.queryParameters['alt'], 'sse');
      expect(sent!.headers['x-goog-api-key'], 'key-123');
      expect(jsonDecode(sentBody!), {
        'systemInstruction': {'parts': [{'text': 'Be brief.'}]},
        'contents': [
          {'role': 'user', 'parts': [{'text': 'Hi'}]},
          {'role': 'model', 'parts': [{'text': 'Hello!'}]},
          {'role': 'user', 'parts': [{'text': 'Where did my money go?'}]},
        ],
      });
    });

    test('an error status fails the stream with the mapped outcome', () async {
      final adapter = GeminiAdapter(MockClient((_) async => http.Response(
            jsonEncode({'error': {'code': 429, 'message': 'Quota exceeded'}}),
            429,
          )));

      final stream = adapter.streamReply(apiKey: 'k', model: 'm', systemInstruction: '', history: const [], prompt: 'hi');

      expect(stream.toList(), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.noCredit)));
    });

    test("a connection dropped mid-reply fails the stream as Can't reach provider", () async {
      final adapter = GeminiAdapter(MockClient.streaming((_, _) async {
        final body = StreamController<List<int>>();
        body.add(utf8.encode(event('You spent ')));
        body.addError(http.ClientException('Connection closed while receiving data'));
        unawaited(body.close());
        return http.StreamedResponse(body.stream, 200);
      }));

      final stream = adapter.streamReply(apiKey: 'k', model: 'm', systemInstruction: '', history: const [], prompt: 'hi');

      await expectLater(
        stream.toList(),
        throwsA(isA<ProviderFailure>()
            .having((f) => f.outcome, 'outcome', ConnectionOutcome.unreachable)
            .having((f) => f.message, 'message', 'Connection closed while receiving data')),
      );
    });

    test("a reply that isn't JSON fails the stream as Provider error", () async {
      final adapter = GeminiAdapter(MockClient.streaming(
        (_, _) async => http.StreamedResponse(Stream.value(utf8.encode('data: {not json\n\n')), 200),
      ));

      final stream = adapter.streamReply(apiKey: 'k', model: 'm', systemInstruction: '', history: const [], prompt: 'hi');

      await expectLater(
        stream.toList(),
        throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.providerError)),
      );
    });
  });
}
