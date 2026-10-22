import '../../../core/format/money.dart';
import '../models/chat_message.dart';

/// Contract for AI Expense Consultant reasoning and streaming responses.
abstract class ConsultantClient {
  /// False when the client cannot answer at all (no AI Provider key saved),
  /// so the screen can say the Consultant is off before the user types.
  bool get isConfigured;

  /// Who answers the next message, as "Google Gemini · gemini-2.5-flash", or null when
  /// not configured. A change mid-conversation adds a marker line.
  String? get answeredBy;

  /// [currency] is the Currency chosen in Settings; amounts in
  /// [contextSummary] are already labelled with it.
  Stream<String> streamConsultantResponse({
    required String prompt,
    required String contextSummary,
    required Currency currency,
    List<ChatMessage> conversationHistory = const [],
  });
}

/// The Consultant's system prompt: how to answer, which Currency amounts
/// are in, and the user's data.
String consultantSystemInstruction({required String contextSummary, required Currency currency}) => '''
You are the AI Expense Consultant for a minimalist personal budget app.
Your mission is to provide clear, actionable financial insights, spending analysis, and smart budgeting tips.

Guidelines:
- Always base your answers on the user's spending data provided below.
- Be concise, direct, supportive, and non-judgmental.
- All amounts are in ${currency.code}. When referencing numbers, write the amount followed by ${currency.code} (e.g., 25 ${currency.code}), never another currency or symbol, and never convert.
- If the user has no recorded expenses, gently explain that you will provide deeper insights once they log a few transactions.

Here is the user's current spending breakdown and recent transactions:
$contextSummary
''';
