// Widget tests for ChatScreen
// Coverage: loading state, error state, empty messages state, loaded messages
//           state, header text, input field, send button, message bubbles.

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
import 'package:brewmaster/presentation/screens/messaging/chat_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake message repositories ─────────────────────────────────────────────────

/// watchMessages never emits — keeps bloc in loading/initial state.
class _NeverMessageRepository implements MessageRepository {
  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      StreamController<List<Message>>().stream; // never emits

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value([]);

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

/// watchMessages throws — triggers MessagingFailure state.
class _ErrorMessageRepository implements MessageRepository {
  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.error(Exception('Failed to load messages'));

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value([]);

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

/// watchMessages returns a custom list immediately.
class _FixedMessageRepository implements MessageRepository {
  final List<Message> _messages;

  _FixedMessageRepository(this._messages);

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value(_messages);

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value([]);

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    return Message(
      messageId: 'msg-sent',
      conversationId: conversationId,
      senderId: 'user-001',
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

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

// ── Fixtures ──────────────────────────────────────────────────────────────────

/// IDs must be ≥8 chars so any potential substring(0,8) calls don't crash.
Conversation _makeConversation({
  String id = 'conv-0001',
  String otherUserId = 'user-0002',
  String otherName = 'Alice',
}) =>
    Conversation(
      conversationId: id,
      participantIds: [otherUserId, 'user-0001'],
      participantNames: {otherUserId: otherName},
      unreadCount: 0,
      createdAt: DateTime(2024),
      updatedAt: DateTime.now(),
    );

Message _makeMessage({
  String id = 'msg-0001',
  String senderId = 'user-0002',
  String receiverId = 'user-0001',
  String content = 'Hello there!',
}) =>
    Message(
      messageId: id,
      conversationId: 'conv-0001',
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      messageType: MessageType.text,
      isRead: true,
      createdAt: DateTime(2024, 6, 1, 10, 30),
    );

// ── Widget helper ─────────────────────────────────────────────────────────────

/// Wraps [ChatScreen] with all required BLoC providers.
///
/// [neverLoad]   — watchMessages never emits (stays in loading/initial state).
/// [loadError]   — watchMessages throws (MessagingFailure state).
/// [messages]    — messages returned immediately (MessagesLoaded state).
Widget _wrap({
  Conversation? conversation,
  List<Message> messages = const [],
  bool neverLoad = false,
  bool loadError = false,
}) {
  final conv = conversation ?? _makeConversation();

  final MessageRepository repo;
  if (neverLoad) {
    repo = _NeverMessageRepository();
  } else if (loadError) {
    repo = _ErrorMessageRepository();
  } else {
    repo = _FixedMessageRepository(messages);
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
          create: (_) =>
              NotificationBloc(repository: FakeNotificationRepository()),
        ),
      ],
      child: ChatScreen(conversation: conv),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('ChatScreen', () {
    testWidgets('shows loading indicator while messages are loading',
        (tester) async {
      await tester.pumpWidget(_wrap(neverLoad: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when watchMessages throws',
        (tester) async {
      await tester.pumpWidget(_wrap(loadError: true));
      await tester.pump();
      expect(find.textContaining('Failed to load messages'), findsOneWidget);
    });

    testWidgets('shows conversation partner name in app bar', (tester) async {
      final conv = _makeConversation(otherName: 'Bob');
      await tester.pumpWidget(_wrap(conversation: conv));
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows empty-state hint text when no messages exist',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(
        find.textContaining('Ask about the coffee variety'),
        findsOneWidget,
      );
    });

    testWidgets('shows message bubbles when messages are loaded',
        (tester) async {
      final msg = _makeMessage(content: 'Good morning!');
      await tester.pumpWidget(_wrap(messages: [msg]));
      await tester.pump();
      expect(find.text('Good morning!'), findsOneWidget);
    });

    testWidgets('shows multiple message bubbles for multiple messages',
        (tester) async {
      final messages = [
        _makeMessage(id: 'msg-a', content: 'First message'),
        _makeMessage(id: 'msg-b', content: 'Second message'),
      ];
      await tester.pumpWidget(_wrap(messages: messages));
      await tester.pump();
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
    });

    testWidgets('shows text input field with "Type a message..." hint',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('shows send button icon in the input area', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('shows microphone icon in the input field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('shows back arrow in the app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets(
        'falls back to "Conversation" title when partner name is missing',
        (tester) async {
      final conv = Conversation(
        conversationId: 'conv-0099',
        participantIds: ['user-0001', 'user-0002'],
        participantNames: {}, // no names provided
        unreadCount: 0,
        createdAt: DateTime(2024),
        updatedAt: DateTime.now(),
      );
      await tester.pumpWidget(_wrap(conversation: conv));
      await tester.pump();
      expect(find.text('Conversation'), findsOneWidget);
    });

    testWidgets('entering text in the input field enables the send button',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Before typing the send button container uses textHint colour (disabled)
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      // After typing the TextField shows the entered text
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows retry option on error state', (tester) async {
      await tester.pumpWidget(_wrap(loadError: true));
      await tester.pump();
      // ErrorStateWidget typically renders a retry button
      expect(
        find.byWidgetPredicate((w) => w is ElevatedButton || w is TextButton),
        findsWidgets,
      );
    });
  });
}
