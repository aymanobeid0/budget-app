import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/money.dart';
import '../../categories/category_store.dart';
import '../../expenses/expense_ledger.dart';
import '../../income/income_ledger.dart';
import '../data/consultant_client.dart';
import '../data/spending_context_builder.dart';
import '../models/chat_message.dart';
import 'consultant_state.dart';

class ConsultantCubit extends Cubit<ConsultantState> {
  ConsultantCubit({
    required this.ledger,
    required this.categoryStore,
    this.incomeLedger,
    Currency Function()? currency,
    required this.client,
  })  : _currency = currency ?? (() => Currency.fallback),
        super(const ConsultantState());

  final ExpenseLedger ledger;
  final CategoryStore categoryStore;

  /// Gives the consultant the user's Income; without it advice is
  /// spending-only.
  final IncomeLedger? incomeLedger;
  final ConsultantClient client;

  /// The Currency chosen in Settings at the time a message is sent.
  final Currency Function() _currency;

  StreamSubscription<String>? _streamSub;

  /// Who answered the last message sent, to spot a provider switch.
  String? _lastAnsweredBy;

  Future<void> sendMessage(String prompt) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty || state.isStreaming) return;

    final now = DateTime.now();
    final userMessage = ChatMessage(
      id: 'usr_${now.millisecondsSinceEpoch}',
      text: cleanPrompt,
      isUser: true,
      timestamp: now,
    );

    final assistantMsgId = 'ai_${now.millisecondsSinceEpoch}';
    final placeholderAssistantMessage = ChatMessage(
      id: assistantMsgId,
      text: '',
      isUser: false,
      timestamp: now,
      isStreaming: true,
    );

    final priorHistory = state.messages
        .where((m) => !m.isStreaming && !m.isMarker && m.text.isNotEmpty)
        .toList();

    final answeredBy = client.answeredBy;
    final switched = state.messages.isNotEmpty && _lastAnsweredBy != null && answeredBy != null && answeredBy != _lastAnsweredBy;
    _lastAnsweredBy = answeredBy;

    final updatedMessages = [
      ...state.messages,
      if (switched)
        ChatMessage(
          id: 'mkr_${now.millisecondsSinceEpoch}',
          text: 'Now answering with $answeredBy',
          isUser: false,
          timestamp: now,
          isMarker: true,
        ),
      userMessage,
      placeholderAssistantMessage,
    ];

    emit(state.copyWith(
      messages: updatedMessages,
      status: ConsultantStatus.streaming,
      errorMessage: null,
    ));

    try {
      final expenses = await ledger.loadExpenses();
      final categories = await categoryStore.loadCategories();
      final income = await incomeLedger?.loadIncome() ?? const [];
      final incomeSources = await incomeLedger?.loadSources(includeDeleted: true) ?? const [];
      final currency = _currency();
      final contextSummary = SpendingContextBuilder.build(
        expenses: expenses,
        categories: categories,
        income: income,
        incomeSources: incomeSources,
        currency: currency,
      );

      final stream = client.streamConsultantResponse(
        prompt: cleanPrompt,
        contextSummary: contextSummary,
        currency: currency,
        conversationHistory: priorHistory,
      );

      final buffer = StringBuffer();

      _streamSub = stream.listen(
        (chunk) {
          buffer.write(chunk);
          if (isClosed) return;

          final currentMessages = List<ChatMessage>.from(state.messages);
          final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              text: buffer.toString(),
              isStreaming: true,
            );
            emit(state.copyWith(messages: currentMessages));
          }
        },
        onDone: () {
          if (isClosed) return;
          final currentMessages = List<ChatMessage>.from(state.messages);
          final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              text: buffer.isEmpty ? 'No response received from consultant.' : buffer.toString(),
              isStreaming: false,
            );
            emit(state.copyWith(
              messages: currentMessages,
              status: ConsultantStatus.idle,
            ));
          }
        },
        onError: (error) {
          if (isClosed) return;
          final currentMessages = List<ChatMessage>.from(state.messages);
          final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              text: buffer.isEmpty
                  ? 'Unable to reach the AI provider. Check your connection and your key in Settings.'
                  : buffer.toString(),
              isStreaming: false,
            );
            emit(state.copyWith(
              messages: currentMessages,
              status: ConsultantStatus.error,
              errorMessage: error.toString(),
            ));
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (isClosed) return;
      final currentMessages = List<ChatMessage>.from(state.messages);
      final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1) {
        currentMessages[index] = currentMessages[index].copyWith(
          text: 'Unable to reach the AI provider. Check your connection and your key in Settings.',
          isStreaming: false,
        );
      }
      emit(state.copyWith(
        messages: currentMessages,
        status: ConsultantStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void clearChat() {
    emit(state.copyWith(messages: []));
  }

  Future<void> retryLastMessage() async {
    if (state.isStreaming) return;
    ChatMessage? lastUserMsg;
    for (var i = state.messages.length - 1; i >= 0; i--) {
      if (state.messages[i].isUser) {
        lastUserMsg = state.messages[i];
        break;
      }
    }
    if (lastUserMsg != null && lastUserMsg.text.isNotEmpty) {
      await sendMessage(lastUserMsg.text);
    }
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}
