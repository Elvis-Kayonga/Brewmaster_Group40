import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:brewmaster/data/providers/auth_provider.dart' as app;
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/data/services/user_service.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';

// Minimal user implementation that allows setting emailVerified and
// providerData. We only implement the getters that the code inspects.
class TestUser implements fb.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final List<fb.UserInfo> providerData;

  TestUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.providerData = const [],
  });

  // everything else is unneeded for the test
  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestUserInfo implements fb.UserInfo {
  @override
  final String providerId;
  @override
  final String? uid;
  @override
  final String? displayName;
  @override
  final String? photoURL;
  @override
  final String? email;
  @override
  final String? phoneNumber;

  TestUserInfo({
    required this.providerId,
    this.uid,
    this.displayName,
    this.photoURL,
    this.email,
    this.phoneNumber,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// A fake auth service that simply returns a predetermined user.
class FakeAuthService extends AuthService {
  final fb.User? fakeUser;
  FakeAuthService({this.fakeUser})
    : super(
        auth: _FakeFirebaseAuth(fakeUser),
        googleSignIn: _FakeGoogleSignIn(),
      );

  @override
  fb.User? get currentUser => fakeUser;

  @override
  Stream<fb.User?> get authStateChanges => Stream.value(fakeUser);
}

// Minimal FirebaseAuth mock
class _FakeFirebaseAuth implements fb.FirebaseAuth {
  final fb.User? _user;
  _FakeFirebaseAuth(this._user);

  @override
  fb.User? get currentUser => _user;

  @override
  Stream<fb.User?> authStateChanges() => Stream.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Minimal GoogleSignIn mock
class _FakeGoogleSignIn implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Minimal Firestore mock
class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Captures the profile passed to createUserProfile.
class CapturingUserService extends UserService {
  UserProfile? lastCreated;

  CapturingUserService() : super(firestore: _FakeFirebaseFirestore());

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    lastCreated = profile;
    // do not call super which writes to Firestore
  }
}

void main() {
  testWidgets('Profile setup marks google accounts verified', (
    WidgetTester tester,
  ) async {
    // create a fake Google user that reports emailVerified=false but
    // providerData includes google.com
    final googleUser = TestUser(
      uid: 'test-google-id',
      email: 'google@user.com',
      emailVerified: false,
      providerData: [
        TestUserInfo(providerId: 'google.com', uid: 'test-google-id'),
      ],
    );

    final authProvider = app.AuthProvider(
      authService: FakeAuthService(fakeUser: googleUser),
    )..init();
    final fakeService = CapturingUserService();
    final userProvider = UserProvider(userService: fakeService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<app.AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: const MaterialApp(
          home: ProfileSetupScreen(
            userId: 'test-google-id',
            email: 'google@user.com',
            displayName: 'Google User',
            role: UserRole.buyer,
          ),
        ),
      ),
    );

    // fill the required buyer fields to make form valid
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Coffee');
    await tester.enterText(find.byType(TextFormField).at(1), 'Roaster');
    await tester.enterText(find.byType(TextFormField).at(2), '100');

    // tap save
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(fakeService.lastCreated, isNotNull);
    expect(fakeService.lastCreated!.isVerified, isTrue);
    expect(
      fakeService.lastCreated!.verificationStatus,
      equals(VerificationStatus.verified),
    );
  });

  testWidgets('Profile setup respects emailVerified status', (
    WidgetTester tester,
  ) async {
    final emailUser = TestUser(
      uid: 'test-email-id',
      email: 'email@user.com',
      emailVerified: true,
      providerData: [],
    );

    final authProvider = app.AuthProvider(
      authService: FakeAuthService(fakeUser: emailUser),
    )..init();
    final fakeService = CapturingUserService();
    final userProvider = UserProvider(userService: fakeService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<app.AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: const MaterialApp(
          home: ProfileSetupScreen(
            userId: 'test-email-id',
            email: 'email@user.com',
            displayName: 'Email User',
            role: UserRole.farmer,
          ),
        ),
      ),
    );

    // fill some farmer fields
    await tester.enterText(find.byType(TextFormField).at(0), '5');
    await tester.enterText(find.byType(TextFormField).at(1), 'Somewhere');
    await tester.enterText(find.byType(TextFormField).at(2), 'Bourbon');
    await tester.enterText(find.byType(TextFormField).at(3), 'REG-12345');

    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();

    expect(fakeService.lastCreated, isNotNull);
    expect(fakeService.lastCreated!.isVerified, isTrue);
    expect(
      fakeService.lastCreated!.verificationStatus,
      equals(VerificationStatus.verified),
    );
  });
}
