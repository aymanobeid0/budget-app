import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.isMarker = false,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  /// A line in the thread rather than a turn, such as "Now answering with
  /// OpenAI · gpt-4.1-mini". Never sent to the provider.
  final bool isMarker;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
    bool? isMarker,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isMarker: isMarker ?? this.isMarker,
    );
  }

  @override
  List<Object?> get props => [id, text, isUser, timestamp, isStreaming, isMarker];
}
