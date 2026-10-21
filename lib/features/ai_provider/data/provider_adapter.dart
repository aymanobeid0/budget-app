import '../../consultant/models/chat_message.dart';

/// One AI Provider's HTTP API: list its chat models, check that a model
/// answers, and stream a Consultant reply. Every failure is thrown as a
/// `ProviderFailure`.
abstract class ProviderAdapter {
  /// The chat-capable model ids the key can use, sorted. Doubles as the key
  /// test.
  Future<List<String>> listModels(String apiKey);

  /// A one-token request to [model]: proves key, model and credit together.
  Future<void> ping(String apiKey, String model);

  Stream<String> streamReply({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<ChatMessage> history,
    required String prompt,
  });
}
