// Integration tests for auth-screen-routing-fix
// Task 7.1: Full unauthenticated launch → LoginScreen flow
// Task 7.2: Full authenticated launch → main content flow

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
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
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
// Helpers
// ---------------------------------------------------------------------------

UserProfile _fakeProfile({required String uid, required String email}) {
  final now = DateTime.now();
  return UserProfile(
    id: uid,
    email: email,
    phoneNumber: '',
    role: UserRole.buyer,
    displayName: 'Test User',
    createdAt: now,
    updatedAt: now,
    isVerified: true,
    verificationStatus: VerificationStatus.verified,
  );
}

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
}

class _FakePaymentRepository implements PaymentRepository {
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
}

class _FakeNotificationRepository implements NotificationRepository {
  @override Future<bool> requestPermission() async => false;
  @override Future<String?> getToken() async => null;
  @override Stream<Map<String, dynamic>> watchNotifications() => Stream.value({});
  @override Future<Map<String, bool>> getPreferences() async => {};
  @override Future<void> updatePreferences(Map<String, bool> p) async {}
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

Widget _buildApp({fb.User? user, UserProfile? profile}) {
  final authRepo = _FakeAuthRepository(user);
  final userRepo = _FakeUserRepository(profile);
  return MultiBlocProvider(
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
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Integration 7.1 – Unauthenticated launch → LoginScreen', () {
    testWidgets('AuthGate is present in the widget tree', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGate), findsOneWidget);
    });

    testWidgets('LoginScreen is shown when no user is signed in', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('LoginScreen shows "Welcome Back" heading',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('LoginScreen shows "Sign In as Buyer" button', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.text('Sign In as Buyer'), findsOneWidget);
    });

    testWidgets('LoginScreen shows "Sign in with Google" button', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('LoginScreen shows bolt icon', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('Integration 7.2 – Authenticated launch → DashboardScreen', () {
    late _FakeUser fakeUser;
    late UserProfile fakeProfile;

    setUp(() {
      fakeUser = _FakeUser(
        uid: 'user-integration-001',
        email: 'test@brewmaster.com',
        emailVerified: true,
      );
      fakeProfile = _fakeProfile(
        uid: fakeUser.uid,
        email: fakeUser.email!,
      );
    });

    testWidgets('AuthGate is present in the widget tree', (tester) async {
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: fakeProfile));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGate), findsOneWidget);
    });

    testWidgets('HomeShell is shown when authenticated',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: fakeProfile));
      await tester.pumpAndSettle();

      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('HomeShell shows dashboard AppBar title',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: fakeProfile));
      await tester.pumpAndSettle();

      expect(find.text('My Dashboard'), findsOneWidget);
    });

    testWidgets('Authenticated launch does not show login UI elements',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: fakeProfile));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Welcome Back'), findsNothing);
      expect(find.text('Sign In as Buyer'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
    });
  });
}
