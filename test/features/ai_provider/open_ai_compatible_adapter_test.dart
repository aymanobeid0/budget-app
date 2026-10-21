import 'dart:convert';

import 'package:budget_app/features/ai_provider/data/open_ai_compatible_adapter.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response modelList(List<String> ids) => http.Response(
      jsonEncode({
        'object': 'list',
        'data': [for (final id in ids) {'id': id, 'object': 'model'}],
      }),
      200,
    );

void main() {
  group('listModels', () {
    test("OpenAI lists only gpt and o-series chat models, sorted, with the key as a Bearer token", () async {
      http.Request? sent;
      final adapter = OpenAiCompatibleAdapter.openAi(MockClient((request) async {
        sent = request;
        return modelList([
          'gpt-4.1-mini',
          'o4-mini',
          'gpt-4o-audio-preview',
          'gpt-4o-realtime-preview',
          'gpt-image-1',
          'gpt-4o-transcribe',
          'gpt-4o-mini-tts',
          'gpt-4o-search-preview',
          'text-embedding-3-small',
          'dall-e-3',
          'whisper-1',
          'omni-moderation-latest',
          'gpt-4.1',
          'o3',
        ]);
      }));

      final models = await adapter.listModels('sk-123');

      expect(models, ['gpt-4.1', 'gpt-4.1-mini', 'o3', 'o4-mini']);
      expect(sent!.url.toString(), 'https://api.openai.com/v1/models');
      expect(sent!.headers['authorization'], 'Bearer sk-123');
    });

    test('Groq lists every model except speech-to-text and safety classifiers', () async {
      http.Request? sent;
      final adapter = OpenAiCompatibleAdapter.groq(MockClient((request) async {
        sent = request;
        return modelList([
          'llama-3.3-70b-versatile',
          'whisper-large-v3-turbo',
          'meta-llama/llama-guard-4-12b',
          'openai/gpt-oss-20b',
          'meta-llama/llama-prompt-guard-2-86m',
          'llama-3.1-8b-instant',
        ]);
      }));

      final models = await adapter.listModels('gsk-123');

      expect(models, ['llama-3.1-8b-instant', 'llama-3.3-70b-versatile', 'openai/gpt-oss-20b']);
      expect(sent!.url.toString(), 'https://api.groq.com/openai/v1/models');
      expect(sent!.headers['authorization'], 'Bearer gsk-123');
    });

    test("a rejected key is 'Key not accepted' with OpenAI's message", () async {
      final adapter = OpenAiCompatibleAdapter.openAi(MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Incorrect API key provided: sk-bad.', 'type': 'invalid_request_error', 'code': 'invalid_api_key'},
            }),
            401,
          )));

      expect(
        adapter.listModels('sk-bad'),
        throwsA(isA<ProviderFailure>()
            .having((f) => f.outcome, 'outcome', ConnectionOutcome.keyNotAccepted)
            .having((f) => f.message, 'message', 'Incorrect API key provided: sk-bad.')),
      );
    });
  });

  group('ping', () {
    test('asks the chosen model for a single completion token', () async {
      http.Request? sent;
      final adapter = OpenAiCompatibleAdapter.groq(MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'choices': []}), 200);
      }));

      await adapter.ping('gsk-123', 'llama-3.1-8b-instant');

      expect(sent!.method, 'POST');
      expect(sent!.url.toString(), 'https://api.groq.com/openai/v1/chat/completions');
      expect(sent!.headers['authorization'], 'Bearer gsk-123');
      expect(jsonDecode(sent!.body), {
        'model': 'llama-3.1-8b-instant',
        'messages': [{'role': 'user', 'content': 'ping'}],
        'max_completion_tokens': 1,
      });
    });

    test("no credit left is 'No credit or rate-limited'", () async {
      final adapter = OpenAiCompatibleAdapter.openAi(MockClient((_) async => http.Response(
            jsonEncode({'error': {'message': 'You exceeded your current quota.', 'type': 'insufficient_quota', 'code': 'insufficient_quota'}}),
            429,
          )));

      expect(adapter.ping('k', 'gpt-4.1-mini'), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.noCredit)));
    });

    test("an unknown model is 'Model not found'", () async {
      final adapter = OpenAiCompatibleAdapter.openAi(MockClient((_) async => http.Response(
            jsonEncode({'error': {'message': 'The model `nope` does not exist.', 'type': 'invalid_request_error', 'code': 'model_not_found'}}),
            404,
          )));

      expect(adapter.ping('k', 'nope'), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.modelNotFound)));
    });

    test("a retired Groq model is 'Model not found', though Groq answers 400", () async {
      final adapter = OpenAiCompatibleAdapter.groq(MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'message': 'The model `mixtral-8x7b-32768` has been decommissioned.', 'type': 'invalid_request_error', 'code': 'model_decommissioned'},
            }),
            400,
          )));

      expect(
        adapter.ping('k', 'mixtral-8x7b-32768'),
        throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.modelNotFound)),
      );
    });
  });

  group('streamReply', () {
    String event(Map<String, dynamic> delta) => 'data: ${jsonEncode({
          'object': 'chat.completion.chunk',
          'choices': [
            {'index': 0, 'delta': delta, 'finish_reason': null},
          ],
        })}\n\n';

    test('yields each content delta until [DONE] and sends the system prompt and history as chat messages', () async {
      http.BaseRequest? sent;
      String? sentBody;
      final whole = [
        event({'role': 'assistant', 'content': ''}),
        event({'content': 'You spent '}),
        event({'content': 'most on Food.'}),
        event({}),
        'data: [DONE]\n\n',
      ].join();
      final split = whole.length ~/ 2; // an event cut across two network chunks
      final adapter = OpenAiCompatibleAdapter.openAi(MockClient.streaming((request, bodyStream) async {
        sent = request;
        sentBody = await bodyStream.bytesToString();
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode(whole.substring(0, split)), utf8.encode(whole.substring(split))]),
          200,
        );
      }));

      final chunks = await adapter
          .streamReply(
            apiKey: 'sk-123',
            model: 'gpt-4.1-mini',
            systemInstruction: 'Be brief.',
            history: [
              ChatMessage(id: 'u1', text: 'Hi', isUser: true, timestamp: DateTime(2026)),
              ChatMessage(id: 'a1', text: 'Hello!', isUser: false, timestamp: DateTime(2026)),
            ],
            prompt: 'Where did my money go?',
          )
          .toList();

      expect(chunks, ['You spent ', 'most on Food.']);
      expect(sent!.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(sent!.headers['authorization'], 'Bearer sk-123');
      expect(jsonDecode(sentBody!), {
        'model': 'gpt-4.1-mini',
        'stream': true,
        'messages': [
          {'role': 'system', 'content': 'Be brief.'},
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello!'},
          {'role': 'user', 'content': 'Where did my money go?'},
        ],
      });
    });

    test('an error status fails the stream with the mapped outcome', () async {
      final adapter = OpenAiCompatibleAdapter.groq(MockClient((_) async => http.Response(
            jsonEncode({'error': {'message': 'Rate limit reached', 'type': 'tokens', 'code': 'rate_limit_exceeded'}}),
            429,
          )));

      final stream = adapter.streamReply(apiKey: 'k', model: 'm', systemInstruction: '', history: const [], prompt: 'hi');

      expect(stream.toList(), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.noCredit)));
    });
  });
}
