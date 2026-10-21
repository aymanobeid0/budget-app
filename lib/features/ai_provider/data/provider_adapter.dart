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

/// A provider whose model the user types instead of picking from a list.
/// The Test button calls [testModel] rather than [listModels].
abstract interface class TypedModelAdapter implements ProviderAdapter {
  /// Checks the key, then that [model] is one of the provider's models
  /// (`ConnectionOutcome.modelNotFound` when not). Throws a
  /// `ProviderFailure`.
  Future<void> testModel(String apiKey, String model);
}
