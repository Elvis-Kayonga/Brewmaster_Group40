// test/bloc/messaging_bloc_test.dart
//
// Unit tests for MessagingBloc — conversations, messages, send, mark-read.
// Requirements: 5.2, 5.3, 5.5

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

Conversation _fakeConversation({String id = 'conv-1'}) => Conversation(
      conversationId: id,
      participantIds: ['user-1', 'user-2'],
      participantNames: {'user-1': 'Alice', 'user-2': 'Bob'},
      unreadCount: 0,
      createdAt: _now,
      updatedAt: _now,
    );

Message _fakeMessage({String id = 'msg-1'}) => Message(
      messageId: id,
      conversationId: 'conv-1',
      senderId: 'user-1',
      receiverId: 'user-2',
      content: 'Hello',
      messageType: MessageType.text,
      isRead: false,
      createdAt: _now,
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeMessageRepository implements MessageRepository {
  final StreamController<List<Conversation>> _convoController =
      StreamController<List<Conversation>>.broadcast();
  final StreamController<List<Message>> _msgController =
      StreamController<List<Message>>.broadcast();

  final Message _sentMsg = _fakeMessage();
  final Conversation _conversation = _fakeConversation();
  Exception? _error;

  void setError(Exception e) => _error = e;
  void pushConversations(List<Conversation> c) => _convoController.add(c);
  void pushMessages(List<Message> m) => _msgController.add(m);

  @override
  Stream<List<Conversation>> watchConversations() => _convoController.stream;

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      _msgController.stream;

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    if (_error != null) throw _error!;
    return _sentMsg;
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    if (_error != null) throw _error!;
    return _conversation;
  }

  @override
  Future<int> getTotalUnreadCount() async => 0;

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      PaginatedResult(items: [], cursor: null, hasMore: false);

  void dispose() {
    _convoController.close();
    _msgController.close();
  }

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('MessagingBloc — initial state', () {
    test('starts in MessagingInitial', () {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);
      expect(bloc.state, isA<MessagingInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('MessagingBloc — ConversationsLoadRequested', () {
    test('emits MessagingLoading then ConversationsLoaded via stream',
        () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);
      final states = <MessagingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const ConversationsLoadRequested());
      await Future<void>.delayed(Duration.zero);

      final conv = _fakeConversation();
      repo.pushConversations([conv]);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is MessagingLoading), isTrue);
      expect(states.last, isA<ConversationsLoaded>());
      expect(
          (states.last as ConversationsLoaded).conversations, contains(conv));

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits ConversationsLoaded with empty list', () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);
      final states = <MessagingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const ConversationsLoadRequested());
      await Future<void>.delayed(Duration.zero);

      repo.pushConversations([]);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<ConversationsLoaded>());
      expect((states.last as ConversationsLoaded).conversations, isEmpty);

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });
  });

  group('MessagingBloc — MessagesLoadRequested', () {
    test('emits MessagingLoading then MessagesLoaded via stream', () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);
      final states = <MessagingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MessagesLoadRequested('conv-1'));
      await Future<void>.delayed(Duration.zero);

      final msg = _fakeMessage();
      repo.pushMessages([msg]);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is MessagingLoading), isTrue);
      expect(states.last, isA<MessagesLoaded>());
      expect((states.last as MessagesLoaded).messages, contains(msg));

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });
  });

  group('MessagingBloc — MessageSendRequested', () {
    // The send handler calls repository.sendMessage() but emits no state on
    // success — the Firestore stream subscription will push the new message
    // via _MessagesUpdated. On failure it emits MessagingFailure.
    test('does not change state on successful send', () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);

      bloc.add(const MessageSendRequested(
        conversationId: 'conv-1',
        receiverId: 'user-2',
        content: 'Hello',
      ));
      await Future<void>.delayed(Duration.zero);

      // State remains MessagingInitial — no emit on success
      expect(bloc.state, isA<MessagingInitial>());

      bloc.close();
      repo.dispose();
    });

    test('emits MessagingFailure when send throws', () async {
      final repo = _FakeMessageRepository();
      repo.setError(Exception('send failed'));
      final bloc = MessagingBloc(repository: repo);

      bloc.add(const MessageSendRequested(
        conversationId: 'conv-1',
        receiverId: 'user-2',
        content: 'Hello',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MessagingFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('MessagingBloc — StartConversationRequested', () {
    test('emits ConversationReady on success', () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);

      bloc.add(const StartConversationRequested('user-2'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ConversationReady>());

      bloc.close();
      repo.dispose();
    });

    test('emits MessagingFailure on exception', () async {
      final repo = _FakeMessageRepository();
      repo.setError(Exception('network error'));
      final bloc = MessagingBloc(repository: repo);

      bloc.add(const StartConversationRequested('user-2'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MessagingFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('MessagingBloc — MessagesMarkReadRequested', () {
    test('does not change state when mark-read succeeds', () async {
      final repo = _FakeMessageRepository();
      final bloc = MessagingBloc(repository: repo);

      bloc.add(const MessagesMarkReadRequested('conv-1'));
      await Future<void>.delayed(Duration.zero);

      // State stays MessagingInitial (no state emitted for mark-read)
      expect(bloc.state, isA<MessagingInitial>());

      bloc.close();
      repo.dispose();
    });
  });
}
