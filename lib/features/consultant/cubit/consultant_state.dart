import 'package:equatable/equatable.dart';

import '../models/chat_message.dart';

enum ConsultantStatus {
  idle,
  streaming,
  error,
}

class ConsultantState extends Equatable {
  const ConsultantState({
    this.messages = const [],
    this.status = ConsultantStatus.idle,
    this.suggestedPrompts = const [
      'Where did I spend the most?',
      'Summarize my monthly expenses',
      'How can I cut spending?',
      'What are my top categories?',
    ],
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final ConsultantStatus status;
  final List<String> suggestedPrompts;
  final String? errorMessage;

  bool get isStreaming => status == ConsultantStatus.streaming;

  ConsultantState copyWith({
    List<ChatMessage>? messages,
    ConsultantStatus? status,
    List<String>? suggestedPrompts,
    String? errorMessage,
  }) {
    return ConsultantState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [messages, status, suggestedPrompts, errorMessage];
}
