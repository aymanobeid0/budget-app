import 'package:budget_app/features/ai_provider/data/provider_adapter.dart';
import 'package:budget_app/features/ai_provider/models/ai_provider.dart';
import 'package:budget_app/features/consultant/models/chat_message.dart';

/// A provider whose answers the test sets: [models] for Test, [pingFailure]
/// for Save's check, [chatFailure] or [reply] for a chat.
class FakeProviderAdapter implements ProviderAdapter {
  List<String> models = const ['model-a', 'model-b'];
  ProviderFailure? listFailure;
  ProviderFailure? pingFailure;
  ProviderFailure? chatFailure;
  List<String> reply = const ['Hello ', 'there'];
  String? lastChatKey;
  String? lastChatModel;

  @override
  Future<List<String>> listModels(String apiKey) async {
    if (listFailure != null) throw listFailure!;
    return models;
  }

  @override
  Future<void> ping(String apiKey, String model) async {
    if (pingFailure != null) throw pingFailure!;
  }

  @override
  Stream<String> streamReply({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<ChatMessage> history,
    required String prompt,
  }) async* {
    lastChatKey = apiKey;
    lastChatModel = model;
    if (chatFailure != null) throw chatFailure!;
    yield* Stream.fromIterable(reply);
  }
}
