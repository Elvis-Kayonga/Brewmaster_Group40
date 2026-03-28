import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/messaging/chat_screen.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  @override
  fb.User? get currentUser => null;
  @override
  Stream<fb.User?> get authStateChanges => Stream.value(null);
  @override
  Future<fb.User?> register(String email, String password) async => null;
  @override
  Future<fb.User?> signIn(String email, String password) async => null;
  @override
  Future<fb.User?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<bool> sendEmailVerification() async => false;
  @override
  Future<bool> isEmailVerified() async => false;
}

class _FakeMessageRepository implements MessageRepository {
  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async =>
      throw UnimplementedError();
  @override
  Stream<List<Conversation>> watchConversations() => Stream.value([]);
  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value([]);
  @override
  Future<void> markConversationAsRead(String conversationId) async {}
  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async =>
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

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<Map<String, dynamic>> watchNotifications() => Stream.value({});
  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {}
  @override
  Future<Map<String, bool>> getPreferences() async => {};
  @override
  Future<void> saveNotification(AppNotification notification) async {}
  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      Stream.value([]);
  @override
  Future<void> markAsRead(String notificationId, String userId) async {}
  @override
  Future<void> markAllAsRead(String userId) async {}
  @override
  Future<int> getUnreadCount(String userId) async => 0;
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile?> getUserProfile(String userId) async => null;
  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => null;
  @override
  Future<void> createUserProfile(UserProfile profile) async {}
  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}
  @override
  Stream<UserProfile?> watchUserProfile(String userId) => Stream.value(null);

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Conversation _makeConversation() => Conversation(
      conversationId: 'test-conv-123',
      participantIds: ['user1', 'user2'],
      participantNames: {'user1': 'Alice', 'user2': 'Bob'},
      lastMessage: null,
      unreadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

Widget _wrap(Widget child) => MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: _FakeAuthRepository(),
            userRepository: _FakeUserRepository(),
          ),
        ),
        BlocProvider<MessagingBloc>(
          create: (_) => MessagingBloc(repository: _FakeMessageRepository()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: _FakeUserRepository()),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) =>
              NotificationBloc(repository: _FakeNotificationRepository()),
        ),
      ],
      child: MaterialApp(home: child),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('ChatScreen Widget Tests', () {
    testWidgets('displays app bar', (tester) async {
      await tester.pumpWidget(_wrap(ChatScreen(conversation: _makeConversation())));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays message input field with correct hint', (tester) async {
      await tester.pumpWidget(_wrap(ChatScreen(conversation: _makeConversation())));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('send button uses arrow_upward icon', (tester) async {
      await tester.pumpWidget(_wrap(ChatScreen(conversation: _makeConversation())));
      await tester.pump();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('shows loading on initial BLoC state', (tester) async {
      await tester.pumpWidget(_wrap(ChatScreen(conversation: _makeConversation())));
      // Before settling — MessagingInitial triggers LoadingIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('input field accepts text entry', (tester) async {
      await tester.pumpWidget(_wrap(ChatScreen(conversation: _makeConversation())));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello!');
      await tester.pump();

      expect(find.text('Hello!'), findsOneWidget);
    });
  });
}
