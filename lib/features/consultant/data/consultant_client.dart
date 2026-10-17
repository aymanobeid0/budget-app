import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/chat_message.dart';

/// Contract for AI Expense Consultant reasoning and streaming responses.
abstract class ConsultantClient {
  /// False when the client cannot answer at all (no Gemini key), so the
  /// screen can say the Consultant is off before the user types.
  bool get isConfigured;

  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    List<ChatMessage> conversationHistory = const [],
  });
}

/// Production implementation backed by Google Gemini.
class GeminiConsultantClient implements ConsultantClient {
  GeminiConsultantClient({
    required this.apiKey,
    this.modelName = 'gemini-1.5-flash',
  });

  final String apiKey;
  final String modelName;

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    List<ChatMessage> conversationHistory = const [],
  }) async* {
    if (apiKey.isEmpty) {
      yield 'Google Gemini API key is missing. Please configure GEMINI_API_KEY to enable the AI Consultant.';
      return;
    }

    final systemInstruction = '''
You are the AI Expense Consultant for a minimalist personal budget app.
Your mission is to provide clear, actionable financial insights, spending analysis, and smart budgeting tips.

Guidelines:
- Always base your answers on the user's spending data provided below.
- Be concise, direct, supportive, and non-judgmental.
- When referencing numbers, use standard currency format (e.g., \$25.00).
- If the user has no recorded expenses, gently explain that you will provide deeper insights once they log a few transactions.

Here is the user's current spending breakdown and recent transactions:
$contextSummary
''';

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );

    // Convert history into Gemini Content objects
    final history = <Content>[];
    for (final msg in conversationHistory) {
      if (msg.isUser) {
        history.add(Content.text(msg.text));
      } else {
        history.add(Content.model([TextPart(msg.text)]));
      }
    }

    final chat = model.startChat(history: history);
    final responseStream = chat.sendMessageStream(Content.text(prompt));

    await for (final response in responseStream) {
      final text = response.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}
