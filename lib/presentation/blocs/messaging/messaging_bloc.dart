import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';
import '../../../domain/repositories/message_repository.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

/// BLoC for messaging — conversations and chat messages.
///
/// Events: [ConversationsLoadRequested], [MessagesLoadRequested],
///         [MessageSendRequested], [MessagesMarkReadRequested]
/// Requirements: 5.2, 5.3, 5.5, 5.6
/// Developer: Developer 3
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessageRepository _repository;

  StreamSubscription<List<Conversation>>? _conversationsSub;
  StreamSubscription<List<Message>>? _messagesSub;

  MessagingBloc({required MessageRepository repository})
      : _repository = repository,
        super(const MessagingInitial()) {
    on<ConversationsLoadRequested>(_onLoadConversations);
    on<MessagesLoadRequested>(_onLoadMessages);
    on<MessageSendRequested>(_onSendMessage);
    on<MessagesMarkReadRequested>(_onMarkRead);
    on<StartConversationRequested>(_onStartConversation);
    on<_ConversationsUpdated>(_onConversationsUpdated);
    on<_MessagesUpdated>(_onMessagesUpdated);
    on<_StreamError>(_onStreamError);
  }

  Future<void> _onStartConversation(
    StartConversationRequested event,
    Emitter<MessagingState> emit,
  ) async {
    emit(const MessagingLoading());
    try {
      final conversation =
          await _repository.getOrCreateConversation(event.otherUserId);
      emit(ConversationReady(conversation));
    } catch (e) {
      emit(MessagingFailure(e.toString()));
    }
  }

  bool _migrationDone = false;

  Future<void> _onLoadConversations(
    ConversationsLoadRequested event,
    Emitter<MessagingState> emit,
  ) async {
    emit(const MessagingLoading());
    // Backfill participantPhotoUrls once per session (user is authenticated here).
    if (!_migrationDone) {
      _migrationDone = true;
      _repository.migrateParticipantPhotoUrls().catchError((_) {});
    }
    await _conversationsSub?.cancel();
    _conversationsSub = _repository.watchConversations().listen(
      (convos) => add(_ConversationsUpdated(convos)),
      onError: (e) => add(_StreamError(e.toString())),
    );
  }

  void _onConversationsUpdated(
    _ConversationsUpdated event,
    Emitter<MessagingState> emit,
  ) {
    emit(ConversationsLoaded(event.conversations));
  }

  Future<void> _onLoadMessages(
    MessagesLoadRequested event,
    Emitter<MessagingState> emit,
  ) async {
    emit(const MessagingLoading());
    await _messagesSub?.cancel();
    _messagesSub = _repository.watchMessages(event.conversationId).listen(
      (msgs) => add(_MessagesUpdated(msgs)),
      onError: (e) => add(_StreamError(e.toString())),
    );
  }

  void _onMessagesUpdated(
    _MessagesUpdated event,
    Emitter<MessagingState> emit,
  ) {
    emit(MessagesLoaded(event.messages));
  }

  Future<void> _onSendMessage(
    MessageSendRequested event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _repository.sendMessage(
        conversationId: event.conversationId,
        receiverId: event.receiverId,
        content: event.content,
        messageType: event.messageType,
        listingId: event.listingId,
      );
    } catch (e) {
      emit(MessagingFailure(e.toString()));
    }
  }

  void _onStreamError(
    _StreamError event,
    Emitter<MessagingState> emit,
  ) {
    emit(MessagingFailure(event.message));
  }

  Future<void> _onMarkRead(
    MessagesMarkReadRequested event,
    Emitter<MessagingState> emit,
  ) async {
    try {
      await _repository.markConversationAsRead(event.conversationId);
    } catch (_) {
      // Non-fatal — silently ignore
    }
  }

  @override
  Future<void> close() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    return super.close();
  }
}
