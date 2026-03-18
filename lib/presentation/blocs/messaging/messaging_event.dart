part of 'messaging_bloc.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => [];
}

class ConversationsLoadRequested extends MessagingEvent {
  const ConversationsLoadRequested();
}

class MessagesLoadRequested extends MessagingEvent {
  final String conversationId;
  const MessagesLoadRequested(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class MessageSendRequested extends MessagingEvent {
  final String conversationId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final String? listingId;

  const MessageSendRequested({
    required this.conversationId,
    required this.receiverId,
    required this.content,
    this.messageType = MessageType.text,
    this.listingId,
  });

  @override
  List<Object?> get props =>
      [conversationId, receiverId, content, messageType, listingId];
}

class StartConversationRequested extends MessagingEvent {
  final String otherUserId;
  const StartConversationRequested(this.otherUserId);
  @override
  List<Object?> get props => [otherUserId];
}

class MessagesMarkReadRequested extends MessagingEvent {
  final String conversationId;
  const MessagesMarkReadRequested(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// Internal events for stream updates
class _ConversationsUpdated extends MessagingEvent {
  final List<Conversation> conversations;
  const _ConversationsUpdated(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class _MessagesUpdated extends MessagingEvent {
  final List<Message> messages;
  const _MessagesUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}

class _StreamError extends MessagingEvent {
  final String message;
  const _StreamError(this.message);
  @override
  List<Object?> get props => [message];
}
