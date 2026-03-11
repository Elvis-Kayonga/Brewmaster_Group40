part of 'messaging_bloc.dart';

abstract class MessagingState extends Equatable {
  const MessagingState();
  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class MessagingLoading extends MessagingState {
  const MessagingLoading();
}

class ConversationsLoaded extends MessagingState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends MessagingState {
  final List<Message> messages;
  const MessagesLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class MessagingFailure extends MessagingState {
  final String message;
  const MessagingFailure(this.message);
  @override
  List<Object?> get props => [message];
}
