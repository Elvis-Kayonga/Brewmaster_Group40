// test/responsive/responsive_layout_test.dart
//
// Verifies that key screens render without RenderFlex overflow at both
// small (360×640 — ≤5.5″) and large (430×932 — ≥6.7″) screen sizes,
// and in landscape orientation.
//
// Requirements: 20.1, 20.2, 20.3, 20.4
// Developer: Developer 6

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/enums.dart' hide MessageType;
import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/saved_lots/saved_lots_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/screens/auth/signup_screen.dart';
import 'package:brewmaster/presentation/screens/messaging/conversations_screen.dart';
import 'package:brewmaster/presentation/screens/dashboard/market_prices_screen.dart';

// ─── Screen sizes ────────────────────────────────────────────────────────────

/// Small phone: ~5.0″ (360×640 dp) — representative of budget Android phones.
const _small = Size(360, 640);

/// Large phone: ~6.7″ (430×932 dp) — Pixel 7 Pro / Galaxy S class.
const _large = Size(430, 932);

/// Landscape small phone.
const _smallLandscape = Size(640, 360);

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Pumps [widget] at the given [size] and asserts no overflow.
Future<void> _checkSize(
  WidgetTester tester,
  Widget widget,
  Size size,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
  await tester.pump();
  // RenderFlex overflow manifests as a FlutterError assertion in tests.
  expect(tester.takeException(), isNull,
      reason: 'RenderFlex overflow at $size');
}

Widget _withMaterial(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );

// ─── Entry point ─────────────────────────────────────────────────────────────

void main() {
  // ─── Auth screens ───────────────────────────────────────────────────────────

  group('LoginScreen — responsive', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
      );
    });

    tearDown(() => authBloc.close());

    testWidgets('renders without overflow at small screen', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const LoginScreen(),
        )),
        _small,
      );
    });

    testWidgets('renders without overflow at large screen', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const LoginScreen(),
        )),
        _large,
      );
    });

    testWidgets('renders without overflow in landscape', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const LoginScreen(),
        )),
        _smallLandscape,
      );
    });
  });

  group('SignupScreen — responsive', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
      );
    });

    tearDown(() => authBloc.close());

    testWidgets('renders without overflow at small screen', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const SignupScreen(),
        )),
        _small,
      );
    });

    testWidgets('renders without overflow at large screen', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const SignupScreen(),
        )),
        _large,
      );
    });

    testWidgets('renders without overflow in landscape', (tester) async {
      await _checkSize(
        tester,
        _withMaterial(BlocProvider.value(
          value: authBloc,
          child: const SignupScreen(),
        )),
        _smallLandscape,
      );
    });
  });

  // ─── Conversations screen ───────────────────────────────────────────────────

  group('ConversationsScreen — responsive', () {
    late MessagingBloc messagingBloc;
    late AuthBloc authBloc;

    setUp(() {
      messagingBloc = MessagingBloc(repository: _FakeMessageRepository());
      authBloc = AuthBloc(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
      );
    });

    tearDown(() {
      messagingBloc.close();
      authBloc.close();
    });

    Widget wrap(Widget child) => _withMaterial(MultiBlocProvider(
          providers: [
            BlocProvider.value(value: messagingBloc),
            BlocProvider.value(value: authBloc),
            BlocProvider<ProfileBloc>(
              create: (_) =>
                  ProfileBloc(userRepository: _FakeUserRepository()),
            ),
            BlocProvider<SavedLotsBloc>(create: (_) => SavedLotsBloc(userRepository: _FakeUserRepository())),
            BlocProvider<NotificationBloc>(
              create: (_) => NotificationBloc(
                repository: _FakeNotificationRepository(),
              ),
            ),
          ],
          child: child,
        ));

    testWidgets('renders without overflow at small screen', (tester) async {
      await _checkSize(tester, wrap(const ConversationsScreen()), _small);
    });

    testWidgets('renders without overflow at large screen', (tester) async {
      await _checkSize(tester, wrap(const ConversationsScreen()), _large);
    });

    testWidgets('renders without overflow in landscape', (tester) async {
      await _checkSize(
          tester, wrap(const ConversationsScreen()), _smallLandscape);
    });
  });

  // ─── Market prices screen ───────────────────────────────────────────────────

  group('MarketPricesScreen — responsive', () {
    late MarketPriceBloc marketPriceBloc;
    late AuthBloc authBloc;

    setUp(() {
      marketPriceBloc =
          MarketPriceBloc(repository: _FakeMarketPriceRepository());
      authBloc = AuthBloc(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
      );
    });

    tearDown(() {
      marketPriceBloc.close();
      authBloc.close();
    });

    Widget wrap(Widget child) => _withMaterial(MultiBlocProvider(
          providers: [
            BlocProvider.value(value: marketPriceBloc),
            BlocProvider.value(value: authBloc),
            BlocProvider<ProfileBloc>(
              create: (_) =>
                  ProfileBloc(userRepository: _FakeUserRepository()),
            ),
            BlocProvider<SavedLotsBloc>(create: (_) => SavedLotsBloc(userRepository: _FakeUserRepository())),
            BlocProvider<NotificationBloc>(
              create: (_) => NotificationBloc(
                repository: _FakeNotificationRepository(),
              ),
            ),
          ],
          child: child,
        ));

    testWidgets('renders without overflow at small screen', (tester) async {
      await _checkSize(tester, wrap(const MarketPricesScreen()), _small);
    });

    testWidgets('renders without overflow at large screen', (tester) async {
      await _checkSize(tester, wrap(const MarketPricesScreen()), _large);
    });
  });

  // ─── Minimum tap-target check ───────────────────────────────────────────────

  group('Tap target sizes — minimum 48×48 dp', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(
        authRepository: _FakeAuthRepository(),
        userRepository: _FakeUserRepository(),
      );
    });

    tearDown(() => authBloc.close());

    testWidgets('LoginScreen primary button meets 48dp minimum', (tester) async {
      await tester.binding.setSurfaceSize(_small);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_withMaterial(
        BlocProvider.value(value: authBloc, child: const LoginScreen()),
      ));
      await tester.pump();

      // Find any ElevatedButton and verify its height ≥ 48
      final buttons = tester.widgetList<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      for (final btn in buttons) {
        final renderBox = tester.renderObject<RenderBox>(
          find.byWidget(btn),
        );
        expect(
          renderBox.size.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Button height ${renderBox.size.height} < 48dp',
        );
      }
    });
  });
}

// ─── Fake repositories (minimal stubs) ───────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<User?> register(String email, String password) async => null;

  @override
  Future<User?> signIn(String email, String password) async => null;

  @override
  Future<User?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<bool> sendEmailVerification() async => false;

  @override
  Future<bool> isEmailVerified() async => false;
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
  Stream<UserProfile?> watchUserProfile(String userId) => const Stream.empty();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

class _FakeMessageRepository implements MessageRepository {
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
  Stream<List<Conversation>> watchConversations() => const Stream.empty();

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      const Stream.empty();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

class _FakeMarketPriceRepository implements MarketPriceRepository {
  @override
  Future<List<MarketPrice>> getMarketPrices() async => [];

  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async =>
      [];

  @override
  Future<List<MarketPrice>> syncDailyPrices() async => [];

  @override
  Stream<List<MarketPrice>> watchMarketPrices() => const Stream.empty();

  @override
  DateTime? get lastSyncTime => null;
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<String, dynamic>> watchNotifications() => const Stream.empty();

  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {}

  @override
  Future<Map<String, bool>> getPreferences() async => {};

  @override
  Future<void> saveNotification(AppNotification notification) async {}

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      const Stream.empty();

  @override
  Future<void> markAsRead(String notificationId, String userId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<int> getUnreadCount(String userId) async => 0;
}
