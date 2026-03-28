import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';

// ---------------------------------------------------------------------------
// Minimal fake implementations
// ---------------------------------------------------------------------------

class _FakeUser implements fb.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final List<fb.UserInfo> providerData;
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  String? get phoneNumber => null;

  _FakeUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.providerData = const [],
  });

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserInfo implements fb.UserInfo {
  @override
  final String providerId;
  @override
  final String? uid;
  @override
  String? get displayName => null;
  @override
  String? get photoURL => null;
  @override
  String? get email => null;
  @override
  String? get phoneNumber => null;

  const _FakeUserInfo({required this.providerId, this.uid});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final fb.User? _user;
  _FakeAuthRepository(this._user);

  @override
  fb.User? get currentUser => _user;

  // Use Stream.empty() so AuthBloc does NOT process stream events and
  // override the pre-seeded state set by _SeededAuthBloc.
  @override
  Stream<fb.User?> get authStateChanges => const Stream.empty();

  @override
  Future<fb.User?> register(String email, String password) async => _user;

  @override
  Future<fb.User?> signIn(String email, String password) async => _user;

  @override
  Future<fb.User?> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<bool> sendEmailVerification() async => true;

  @override
  Future<bool> isEmailVerified() async => _user?.emailVerified ?? false;
}

/// Captures the profile passed to [createUserProfile].
/// Returns the captured profile from [getUserProfile] so that
/// [AuthBloc] can settle after profile creation.
class _CapturingUserRepository implements UserRepository {
  UserProfile? lastCreated;

  @override
  Future<UserProfile?> getUserProfile(String userId) async => lastCreated;

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => null;

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    lastCreated = profile;
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}

  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      const Stream.empty();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

/// AuthBloc subclass that immediately emits a pre-seeded state after
/// construction, so tests don't need to wait for async stream processing.
class _SeededAuthBloc extends AuthBloc {
  _SeededAuthBloc({
    required super.authRepository,
    required super.userRepository,
    required AuthState seed,
  }) {
    emit(seed);
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildApp({
  required Widget home,
  required AuthBloc authBloc,
  required UserRepository userRepo,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<ProfileBloc>(
        create: (_) => ProfileBloc(userRepository: userRepo),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('Profile setup marks Google accounts as email-verified but KYC-unverified',
      (WidgetTester tester) async {
    final userRepo = _CapturingUserRepository();
    final googleUser = _FakeUser(
      uid: 'test-google-id',
      email: 'google@user.com',
      emailVerified: false,
      providerData: const [
        _FakeUserInfo(providerId: 'google.com', uid: 'test-google-id'),
      ],
    );
    final authRepo = _FakeAuthRepository(googleUser);

    // Pre-seed the AuthBloc into AuthNeedsProfile(isGoogleUser: true) so
    // _handleSave correctly detects this as a Google account.
    final authBloc = _SeededAuthBloc(
      authRepository: authRepo,
      userRepository: userRepo,
      seed: const AuthNeedsProfile(
        uid: 'test-google-id',
        email: 'google@user.com',
        isGoogleUser: true,
      ),
    );

    await tester.pumpWidget(_buildApp(
      home: const ProfileSetupScreen(
        userId: 'test-google-id',
        email: 'google@user.com',
        displayName: 'Google User',
        role: UserRole.buyer,
      ),
      authBloc: authBloc,
      userRepo: userRepo,
    ));
    await tester.pumpAndSettle();

    // Fill required buyer fields
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), 'Roaster');
    await tester.enterText(find.byType(TextFormField).at(2), '100');

    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(userRepo.lastCreated, isNotNull);
    expect(userRepo.lastCreated!.isVerified, isTrue);
    expect(
      userRepo.lastCreated!.verificationStatus,
      equals(VerificationStatus.unverified),
    );
  });

  testWidgets('Profile setup marks email-only accounts as unverified',
      (WidgetTester tester) async {
    final userRepo = _CapturingUserRepository();
    final emailUser = _FakeUser(
      uid: 'test-email-id',
      email: 'email@user.com',
      emailVerified: false,
      providerData: const [],
    );
    final authRepo = _FakeAuthRepository(emailUser);

    // Pre-seed the AuthBloc into AuthNeedsProfile(isGoogleUser: false) so
    // _handleSave correctly detects this as a non-Google account.
    final authBloc = _SeededAuthBloc(
      authRepository: authRepo,
      userRepository: userRepo,
      seed: const AuthNeedsProfile(
        uid: 'test-email-id',
        email: 'email@user.com',
        isGoogleUser: false,
      ),
    );

    await tester.pumpWidget(_buildApp(
      home: const ProfileSetupScreen(
        userId: 'test-email-id',
        email: 'email@user.com',
        displayName: 'Email User',
        role: UserRole.farmer,
      ),
      authBloc: authBloc,
      userRepo: userRepo,
    ));
    await tester.pumpAndSettle();

    // Fill farmer fields
    await tester.enterText(find.byType(TextFormField).at(0), '5');
    await tester.enterText(find.byType(TextFormField).at(1), 'Somewhere');
    await tester.enterText(find.byType(TextFormField).at(2), 'Bourbon');
    await tester.enterText(find.byType(TextFormField).at(3), 'REG-12345');

    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(userRepo.lastCreated, isNotNull);
    expect(userRepo.lastCreated!.isVerified, isFalse);
    expect(
      userRepo.lastCreated!.verificationStatus,
      equals(VerificationStatus.unverified),
    );
  });
}
