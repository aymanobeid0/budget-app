import 'dart:convert';

import 'package:budget_app/features/ai_provider/data/anthropic_adapter.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response anthropicError(String type, String message, int status) => http.Response(
      jsonEncode({
        'type': 'error',
        'error': {'type': type, 'message': message},
      }),
      status,
    );

void main() {
  group('listModels', () {
    test('lists every model sorted, with the key in x-api-key and the API version header', () async {
      http.Request? sent;
      final adapter = AnthropicAdapter(MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'data': [
              for (final id in ['claude-sonnet-4-6', 'claude-haiku-4-5', 'claude-opus-4-7'])
                {'type': 'model', 'id': id, 'display_name': id},
            ],
            'has_more': false,
          }),
          200,
        );
      }));

      final models = await adapter.listModels('sk-ant-123');

      expect(models, ['claude-haiku-4-5', 'claude-opus-4-7', 'claude-sonnet-4-6']);
      expect(sent!.url.toString(), 'https://api.anthropic.com/v1/models?limit=1000');
      expect(sent!.headers['x-api-key'], 'sk-ant-123');
      expect(sent!.headers['anthropic-version'], '2023-06-01');
      expect(sent!.headers.containsKey('authorization'), isFalse);
    });
  });

  group('ping', () {
    test('asks the chosen model for a single token', () async {
      http.Request? sent;
      final adapter = AnthropicAdapter(MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'type': 'message', 'content': [], 'stop_reason': 'max_tokens'}), 200);
      }));

      await adapter.ping('sk-ant-123', 'claude-haiku-4-5');

      expect(sent!.method, 'POST');
      expect(sent!.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent!.headers['x-api-key'], 'sk-ant-123');
      expect(sent!.headers['anthropic-version'], '2023-06-01');
      expect(jsonDecode(sent!.body), {
        'model': 'claude-haiku-4-5',
        'max_tokens': 1,
        'messages': [{'role': 'user', 'content': 'ping'}],
      });
    });

    Future<ProviderFailure> failureFrom(http.Response response) async {
      final adapter = AnthropicAdapter(MockClient((_) async => response));
      try {
        await adapter.ping('k', 'claude-haiku-4-5');
      } on ProviderFailure catch (failure) {
        return failure;
      }
      fail('ping should have failed');
    }

    test("a rejected key is 'Key not accepted' with Anthropic's message", () async {
      final failure = await failureFrom(anthropicError('authentication_error', 'invalid x-api-key', 401));

      expect(failure.outcome, ConnectionOutcome.keyNotAccepted);
      expect(failure.message, 'invalid x-api-key');
    });

    test("529 overloaded is 'Provider error'", () async {
      final failure = await failureFrom(anthropicError('overloaded_error', 'Overloaded', 529));

      expect(failure.outcome, ConnectionOutcome.providerError);
      expect(failure.message, 'Overloaded');
    });

    test("a low credit balance is 'No credit or rate-limited', though Anthropic answers 400", () async {
      final failure = await failureFrom(anthropicError(
        'invalid_request_error',
        'Your credit balance is too low to access the Anthropic API. Please go to Plans & Billing to upgrade or purchase credits.',
        400,
      ));

      expect(failure.outcome, ConnectionOutcome.noCredit);
    });

    test("an unknown model is 'Model not found'", () async {
      final failure = await failureFrom(anthropicError('not_found_error', 'model: claude-nope', 404));

      expect(failure.outcome, ConnectionOutcome.modelNotFound);
    });
  });

  group('streamReply', () {
    String event(String type, Map<String, dynamic> data) => 'event: $type\ndata: ${jsonEncode({'type': type, ...data})}\n\n';

    String textDelta(String text) => event('content_block_delta', {
          'index': 0,
          'delta': {'type': 'text_delta', 'text': text},
        });

    Stream<String> reply(AnthropicAdapter adapter) =>
        adapter.streamReply(apiKey: 'k', model: 'claude-haiku-4-5', systemInstruction: '', history: const [], prompt: 'hi');

    AnthropicAdapter streaming(String body) => AnthropicAdapter(MockClient.streaming(
          (_, _) async => http.StreamedResponse(Stream.value(utf8.encode(body)), 200),
        ));

    test('yields each text delta and sends the system prompt top-level with the history as messages', () async {
      http.BaseRequest? sent;
      String? sentBody;
      final whole = [
        event('message_start', {
          'message': {'id': 'msg_1', 'type': 'message', 'role': 'assistant', 'content': []},
        }),
        event('content_block_start', {
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        }),
        'event: ping\ndata: {"type": "ping"}\n\n',
        textDelta('You spent '),
        textDelta('most on Food.'),
        event('content_block_stop', {'index': 0}),
        event('message_delta', {
          'delta': {'stop_reason': 'end_turn'},
          'usage': {'output_tokens': 6},
        }),
        event('message_stop', {}),
      ].join();
      final split = whole.length ~/ 2; // an event cut across two network chunks
      final adapter = AnthropicAdapter(MockClient.streaming((request, bodyStream) async {
        sent = request;
        sentBody = await bodyStream.bytesToString();
        return http.StreamedResponse(
          Stream.fromIterable([utf8.encode(whole.substring(0, split)), utf8.encode(whole.substring(split))]),
          200,
        );
      }));

      final chunks = await adapter
          .streamReply(
            apiKey: 'sk-ant-123',
            model: 'claude-haiku-4-5',
            systemInstruction: 'Be brief.',
            history: [
              ChatMessage(id: 'u1', text: 'Hi', isUser: true, timestamp: DateTime(2026)),
              ChatMessage(id: 'a1', text: 'Hello!', isUser: false, timestamp: DateTime(2026)),
            ],
            prompt: 'Where did my money go?',
          )
          .toList();

      expect(chunks, ['You spent ', 'most on Food.']);
      expect(sent!.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent!.headers['x-api-key'], 'sk-ant-123');
      expect(sent!.headers['anthropic-version'], '2023-06-01');
      expect(jsonDecode(sentBody!), {
        'model': 'claude-haiku-4-5',
        'max_tokens': 8192,
        'stream': true,
        'system': 'Be brief.',
        'messages': [
          {'role': 'user', 'content': 'Hi'},
          {'role': 'assistant', 'content': 'Hello!'},
          {'role': 'user', 'content': 'Where did my money go?'},
        ],
      });
    });

    test("an overloaded error event mid-stream fails it as 'Provider error' after the text so far", () async {
      final adapter = streaming([
        textDelta('You spent '),
        event('error', {
          'error': {'type': 'overloaded_error', 'message': 'Overloaded'},
        }),
      ].join());

      final chunks = <String>[];
      Object? error;
      try {
        await for (final chunk in reply(adapter)) {
          chunks.add(chunk);
        }
      } catch (e) {
        error = e;
      }

      expect(chunks, ['You spent ']);
      expect(
        error,
        isA<ProviderFailure>()
            .having((f) => f.outcome, 'outcome', ConnectionOutcome.providerError)
            .having((f) => f.message, 'message', 'Overloaded'),
      );
    });

    test("a rate-limit error event mid-stream is 'No credit or rate-limited'", () async {
      final adapter = streaming(event('error', {
        'error': {'type': 'rate_limit_error', 'message': 'Number of request tokens has exceeded your rate limit.'},
      }));

      expect(reply(adapter).toList(), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.noCredit)));
    });

    test('an error status fails the stream with the mapped outcome', () async {
      final adapter = AnthropicAdapter(MockClient((_) async => anthropicError('overloaded_error', 'Overloaded', 529)));

      expect(reply(adapter).toList(), throwsA(isA<ProviderFailure>().having((f) => f.outcome, 'outcome', ConnectionOutcome.providerError)));
    });
  });
}
