// Widget tests for ConversationsScreen
// Coverage: loading state, error state, empty state, loaded state, search.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/messaging/conversations_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake repos ────────────────────────────────────────────────────────────────

/// watchConversations never emits — keeps bloc in loading state.
class _NeverConversationRepository implements MessageRepository {
  @override
  Stream<List<Conversation>> watchConversations() =>
      StreamController<List<Conversation>>().stream; // never emits

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value([]);

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> markConversationAsRead(String conversationId) async {}

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) =>
      throw UnimplementedError();

  @override
  Future<int> getTotalUnreadCount() async => 0;

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

/// watchConversations throws — keeps bloc in error state.
class _ErrorConversationRepository implements MessageRepository {
  @override
  Stream<List<Conversation>> watchConversations() =>
      Stream.error(Exception('Network error'));

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value([]);

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> markConversationAsRead(String conversationId) async {}

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) =>
      throw UnimplementedError();

  @override
  Future<int> getTotalUnreadCount() async => 0;

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

// ── Fixture ───────────────────────────────────────────────────────────────────

/// IDs must be ≥8 chars to avoid substring(0,8) crash in _ConversationTile.
Conversation _makeConversation({
  String id = 'conv-001',
  String otherUserId = 'user-002',
  String otherName = 'Alice',
  int unreadCount = 0,
}) =>
    Conversation(
      conversationId: id,
      // otherUserId first so firstWhere((id) => id != null) picks it when
      // currentUser is null (as in tests).
      participantIds: [otherUserId, 'user-001'],
      participantNames: {otherUserId: otherName},
      unreadCount: unreadCount,
      createdAt: DateTime(2024),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );

// ── Helper ────────────────────────────────────────────────────────────────────

/// [neverLoad]   — watchConversations never emits (loading state).
/// [loadError]   — watchConversations throws (error state).
/// [conversations] — conversations returned immediately (loaded state).
Widget _wrap({
  List<Conversation> conversations = const [],
  bool neverLoad = false,
  bool loadError = false,
}) {
  final MessageRepository repo;
  if (neverLoad) {
    repo = _NeverConversationRepository();
  } else if (loadError) {
    repo = _ErrorConversationRepository();
  } else {
    final fake = FakeMessageRepository();
    // Override watchConversations to emit the provided list
    repo = _ConversationsOverrideRepository(fake, conversations);
  }

  final userRepo = FakeUserRepository();
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<MessagingBloc>(
          create: (_) => MessagingBloc(repository: repo),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: FakeAuthRepository(),
            userRepository: userRepo,
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: userRepo),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: FakeNotificationRepository()),
        ),
      ],
      child: const ConversationsScreen(),
    ),
  );
}

/// Delegates to [_base] but overrides watchConversations.
class _ConversationsOverrideRepository implements MessageRepository {
  final FakeMessageRepository _base;
  final List<Conversation> _conversations;

  _ConversationsOverrideRepository(this._base, this._conversations);

  @override
  Stream<List<Conversation>> watchConversations() =>
      Stream.value(_conversations);

  @override
  Stream<List<Message>> watchMessages(String id) => _base.watchMessages(id);

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) =>
      _base.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        listingId: listingId,
      );

  @override
  Future<void> markConversationAsRead(String id) =>
      _base.markConversationAsRead(id);

  @override
  Future<Conversation> getOrCreateConversation(String id) =>
      _base.getOrCreateConversation(id);

  @override
  Future<int> getTotalUnreadCount() => _base.getTotalUnreadCount();

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) =>
      _base.getMessagePage(
        conversationId: conversationId,
        pageSize: pageSize,
        startAfter: startAfter,
      );

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('ConversationsScreen', () {
    testWidgets('shows app bar with "Brew Master" title', (tester) async {
      await tester.pumpWidget(_wrap(neverLoad: true));
      await tester.pump();
      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows loading indicator while conversations are loading',
        (tester) async {
      await tester.pumpWidget(_wrap(neverLoad: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when watchConversations throws',
        (tester) async {
      await tester.pumpWidget(_wrap(loadError: true));
      await tester.pump();
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('shows "No Messages" empty state when conversations list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('No Messages'), findsOneWidget);
    });

    testWidgets('shows "Messages" header when conversations are loaded',
        (tester) async {
      await tester.pumpWidget(_wrap(conversations: [_makeConversation()]));
      await tester.pump();
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('shows "DIRECT MESSAGING" label when conversations are loaded',
        (tester) async {
      await tester.pumpWidget(_wrap(conversations: [_makeConversation()]));
      await tester.pump();
      expect(find.text('DIRECT MESSAGING'), findsOneWidget);
    });

    testWidgets('shows search text field when conversations are loaded',
        (tester) async {
      await tester.pumpWidget(_wrap(conversations: [_makeConversation()]));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows conversation name when conversations are loaded',
        (tester) async {
      await tester.pumpWidget(
        _wrap(conversations: [
          _makeConversation(otherUserId: 'user-002', otherName: 'Alice')
        ]),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows multiple conversations in the list', (tester) async {
      await tester.pumpWidget(
        _wrap(conversations: [
          _makeConversation(id: 'conv-001a', otherUserId: 'user-002', otherName: 'Alice'),
          _makeConversation(id: 'conv-002a', otherUserId: 'user-003', otherName: 'Bob'),
        ]),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows unread count badge when unreadCount > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(conversations: [
          _makeConversation(otherName: 'Carol', unreadCount: 3)
        ]),
      );
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows search placeholder hint text', (tester) async {
      await tester.pumpWidget(_wrap(conversations: [_makeConversation()]));
      await tester.pump();
      expect(find.text('Search conversations...'), findsOneWidget);
    });

    testWidgets(
        'empty state shows descriptive text about starting conversations',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(
        find.textContaining('connect with farmers or buyers'),
        findsOneWidget,
      );
    });

    testWidgets('search field accepts input and clears with close button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(conversations: [_makeConversation(otherName: 'Alice')]),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
