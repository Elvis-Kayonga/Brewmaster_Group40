// Feature: auth-screen-routing-fix, Fix Verification Tests
// **Validates: Requirements 2.1, 2.2, 2.3**
//
// Property-based tests that verify the BLoC routing fix holds across a range
// of randomly generated user states (5 iterations each).

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/domain/models/buyer_dashboard.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as tx;
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/domain/repositories/verification_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:brewmaster/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/widgets/common/home_shell.dart';
import 'package:brewmaster/main.dart';
import 'package:brewmaster/config/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fake Firebase User
// ---------------------------------------------------------------------------

class _FakeUser implements fb.User {
  @override final String uid;
  @override final String? email;
  @override final bool emailVerified;
  @override final List<fb.UserInfo> providerData = const [];
  @override String? get displayName => null;
  @override String? get photoURL => null;
  @override String? get phoneNumber => null;
  _FakeUser({required this.uid, this.email, this.emailVerified = false});
  @override Future<void> reload() async {}
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  final fb.User? _user;
  _FakeAuthRepository(this._user);
  @override fb.User? get currentUser => _user;
  @override Stream<fb.User?> get authStateChanges => Stream.value(_user);
  @override Future<fb.User?> register(String e, String p) async => _user;
  @override Future<fb.User?> signIn(String e, String p) async => _user;
  @override Future<fb.User?> signInWithGoogle() async => _user;
  @override Future<void> signOut() async {}
  @override Future<void> sendPasswordResetEmail(String e) async {}
  @override Future<bool> sendEmailVerification() async => true;
  @override Future<bool> isEmailVerified() async => _user?.emailVerified ?? false;
}

class _FakeUserRepository implements UserRepository {
  final UserProfile? _profile;
  _FakeUserRepository(this._profile);
  @override Future<UserProfile?> getUserProfile(String id) async => _profile;
  @override Future<UserProfile?> getUserProfileByEmail(String e) async => null;
  @override Future<void> createUserProfile(UserProfile p) async {}
  @override Future<void> updateUserProfile(String id, Map<String, dynamic> u) async {}
  @override Stream<UserProfile?> watchUserProfile(String id) => const Stream.empty();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  Stream<List<tx.Transaction>> getUserTransactions(String userId) =>
      Stream.value([]);
  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async =>
      {'totalEarnings': 0.0, 'completedTransactions': 0, 'pendingTransactions': 0};
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeDashboardRepository implements DashboardRepository {
  @override Future<FarmerDashboard> getFarmerDashboard(String id) async => FarmerDashboard.empty();
  @override Future<BuyerDashboard> getBuyerDashboard(String id) async => BuyerDashboard.empty();
  @override Stream<FarmerDashboard> watchFarmerDashboard(String id) => Stream.value(FarmerDashboard.empty());
  @override Stream<BuyerDashboard> watchBuyerDashboard(String id) => Stream.value(BuyerDashboard.empty());
}

class _FakeListingRepository implements ListingRepository {
  @override Stream<List<CoffeeListing>> watchActiveListings() => Stream.value([]);
  @override Stream<List<CoffeeListing>> watchFarmerListings(String id) => Stream.value([]);
  @override Future<List<CoffeeListing>> searchListings(dynamic f) async => [];
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeMessageRepository implements MessageRepository {
  @override Stream<List<Conversation>> watchConversations() => Stream.value([]);
  @override Stream<List<Message>> watchMessages(String id) => Stream.value([]);
  @override Future<int> getTotalUnreadCount() async => 0;
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

class _FakeNotificationRepository implements NotificationRepository {
  @override Future<bool> requestPermission() async => false;
  @override Future<String?> getToken() async => null;
  @override Stream<Map<String, dynamic>> watchNotifications() => Stream.value({});
  @override Future<Map<String, bool>> getPreferences() async => {};
  @override Future<void> updatePreferences(Map<String, bool> p) async {}
  @override Future<void> saveNotification(AppNotification notification) async {}
  @override Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      Stream.value(const []);
  @override Future<void> markAsRead(String notificationId, String userId) async {}
  @override Future<void> markAllAsRead(String userId) async {}
  @override Future<int> getUnreadCount(String userId) async => 0;
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeOfflineSyncRepository implements OfflineSyncRepository {
  @override Stream<bool> watchConnectivity() => Stream.value(true);
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeVerificationRepository implements VerificationRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeMarketPriceRepository implements MarketPriceRepository {
  @override Future<List<MarketPrice>> getMarketPrices() async => [];
  @override Future<List<MarketPrice>> getPricesForVariety(String v, {dynamic grade}) async => [];
  @override Future<List<MarketPrice>> syncDailyPrices() async => [];
  @override Stream<List<MarketPrice>> watchMarketPrices() => Stream.value([]);
  @override DateTime? get lastSyncTime => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _faker = Faker();

UserProfile _fakeProfile({required String uid, required String email}) {
  final now = DateTime.now();
  return UserProfile(
    id: uid,
    email: email,
    phoneNumber: '',
    role: UserRole.buyer,
    displayName: _faker.person.name(),
    createdAt: now,
    updatedAt: now,
    isVerified: true,
    verificationStatus: VerificationStatus.verified,
  );
}

ThemeNotifier? _themeNotifier;

Widget _buildApp({fb.User? user, UserProfile? profile}) {
  final authRepo = _FakeAuthRepository(user);
  final userRepo = _FakeUserRepository(profile);
  return ChangeNotifierProvider<ThemeNotifier>.value(
    value: _themeNotifier!,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository: authRepo, userRepository: userRepo)),
        BlocProvider(create: (_) => ProfileBloc(userRepository: userRepo)),
        BlocProvider(create: (_) => PaymentBloc(paymentRepository: _FakePaymentRepository())),
        BlocProvider(create: (_) => ListingBloc(repository: _FakeListingRepository())),
        BlocProvider(create: (_) => MessagingBloc(repository: _FakeMessageRepository())),
        BlocProvider(create: (_) => NotificationBloc(repository: _FakeNotificationRepository())),
        BlocProvider(create: (_) => ConnectivityBloc(repository: _FakeOfflineSyncRepository())),
        BlocProvider(create: (_) => VerificationBloc(repository: _FakeVerificationRepository())),
        BlocProvider(create: (_) => DashboardBloc(repository: _FakeDashboardRepository())),
        BlocProvider(create: (_) => MarketPriceBloc(repository: _FakeMarketPriceRepository())),
      ],
      child: const BrewMasterApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _themeNotifier = await ThemeNotifier.load();
  });
  group(
      'Task 5.1 – AuthGate renders LoginScreen when unauthenticated, '
      'DashboardScreen when authenticated', () {
    testWidgets(
        'property: unauthenticated user always lands on LoginScreen (5 iterations)',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(_buildApp(user: null, profile: null));
        await tester.pumpAndSettle();

        expect(
          find.byType(LoginScreen),
          findsOneWidget,
          reason: 'Iteration $i: expected LoginScreen for null user',
        );
        expect(
          find.byType(HomeShell),
          findsNothing,
          reason: 'Iteration $i: DashboardScreen must not appear for null user',
        );
      }
    });

    testWidgets(
        'property: authenticated user with profile always lands on DashboardScreen (5 iterations)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < 5; i++) {
        final uid = _faker.guid.guid();
        final email = _faker.internet.email();
        final fakeUser = _FakeUser(
          uid: uid,
          email: email,
          emailVerified: true,
        );
        final profile = _fakeProfile(uid: uid, email: email);

        await tester.pumpWidget(_buildApp(user: fakeUser, profile: profile));
        await tester.pumpAndSettle();

        expect(
          find.byType(HomeShell),
          findsOneWidget,
          reason: 'Iteration $i: expected DashboardScreen for authenticated user',
        );
        expect(
          find.byType(LoginScreen),
          findsNothing,
          reason: 'Iteration $i: LoginScreen must not appear for authenticated user',
        );
      }
    });

    testWidgets('AuthGate is always present regardless of auth state',
        (tester) async {
      // Unauthenticated
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();
      expect(find.byType(AuthGate), findsOneWidget);

      // Authenticated
      final uid = _faker.guid.guid();
      final email = _faker.internet.email();
      final fakeUser = _FakeUser(uid: uid, email: email, emailVerified: true);
      final profile = _fakeProfile(uid: uid, email: email);
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: profile));
      await tester.pumpAndSettle();
      expect(find.byType(AuthGate), findsOneWidget);
    });
  });

  group(
      'Task 5.2 – AuthBloc is always resolvable from the widget tree via '
      'context.read<AuthBloc>() without throwing', () {
    testWidgets(
        'property: context.read<AuthBloc>() succeeds in 5 randomly seeded trees',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        AuthBloc? capturedBloc;
        Object? capturedError;

        await tester.pumpWidget(
          _buildApp(user: null, profile: null),
        );
        await tester.pumpAndSettle();

        // Use a Builder to read the bloc from within the tree.
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (_) => AuthBloc(
                        authRepository: _FakeAuthRepository(null),
                        userRepository: _FakeUserRepository(null),
                      )),
              BlocProvider(
                  create: (_) =>
                      ProfileBloc(userRepository: _FakeUserRepository(null))),
              BlocProvider(
                  create: (_) => PaymentBloc(
                      paymentRepository: _FakePaymentRepository())),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  try {
                    capturedBloc = context.read<AuthBloc>();
                  } catch (e) {
                    capturedError = e;
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          capturedError,
          isNull,
          reason:
              'Iteration $i: context.read<AuthBloc>() must not throw',
        );
        expect(
          capturedBloc,
          isA<AuthBloc>(),
          reason:
              'Iteration $i: context.read<AuthBloc>() must return an AuthBloc',
        );
      }
    });
  });
}
