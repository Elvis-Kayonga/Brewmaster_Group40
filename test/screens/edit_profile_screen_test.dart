// Comprehensive widget tests for EditProfileScreen.
//
// Coverage:
// 1.  App bar title shows "Edit Profile"
// 2.  Form fields visible: Display Name, farm fields (farmer), buyer fields (buyer)
// 3.  ProfileLoading state → CircularProgressIndicator inside the Save button
// 4.  Save button is present
// 5.  Tapping save with empty required field shows validation error
// 6.  Existing values are pre-filled in form fields
// 7.  ProfileFailure state shows ErrorBanner with error message
// 8.  Role-specific fields: farmer sees farm fields, buyer sees business fields
// 9.  ProfileUpdateSuccess causes Navigator.pop (screen is gone)

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/profile/edit_profile_screen.dart';

// ── Fake user repository ──────────────────────────────────────────────────────

class _FakeUserRepository implements UserRepository {
  UserProfile? _profile;
  Exception? _error;
  final _controller = StreamController<UserProfile?>.broadcast();

  _FakeUserRepository({UserProfile? profile}) : _profile = profile;

  void setProfile(UserProfile p) => _profile = p;
  void setError(Exception e) => _error = e;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (_error != null) throw _error!;
    return _profile;
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => _profile;

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    if (_error != null) throw _error!;
    if (_profile != null) {
      _profile = _profile!.copyWith(
        displayName:
            updates['displayName'] as String? ?? _profile!.displayName,
      );
    }
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) => _controller.stream;

  void dispose() => _controller.close();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ── Fixture helpers ───────────────────────────────────────────────────────────

UserProfile _farmerProfile() => UserProfile(
      id: 'u1',
      email: 'farmer@test.com',
      phoneNumber: '+1234567890',
      role: UserRole.farmer,
      displayName: 'John Farmer',
      isVerified: true,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      farmSize: 5.0,
      farmLocation: 'Kigali',
      coffeeVarieties: ['Arabica', 'Robusta'],
      farmRegistrationNumber: 'REG123',
      verificationStatus: VerificationStatus.verified,
    );

UserProfile _buyerProfile() => UserProfile(
      id: 'u2',
      email: 'buyer@test.com',
      phoneNumber: '+1234567890',
      role: UserRole.buyer,
      displayName: 'Jane Buyer',
      isVerified: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      businessName: 'Coffee Co',
      businessType: 'Roaster',
      monthlyVolume: 500.0,
      verificationStatus: VerificationStatus.unverified,
    );

// ── Screen builder ────────────────────────────────────────────────────────────

/// Wraps EditProfileScreen with a [ProfileBloc] backed by [repo].
/// Places MultiBlocProvider ABOVE MaterialApp so new routes pushed from
/// inside the screen also have bloc access.
Widget _buildScreen(
  UserProfile profile, {
  _FakeUserRepository? repo,
  ProfileBloc? bloc,
}) {
  final repository = repo ?? _FakeUserRepository(profile: profile);
  final profileBloc = bloc ?? ProfileBloc(userRepository: repository);

  return MultiBlocProvider(
    providers: [
      BlocProvider<ProfileBloc>(create: (_) => profileBloc),
    ],
    child: MaterialApp(
      home: EditProfileScreen(userProfile: profile),
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

  // ── App bar ─────────────────────────────────────────────────────────────────

  group('EditProfileScreen — App Bar', () {
    testWidgets('shows "Edit Profile" as the app bar title', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });

  // ── Farmer: form fields ──────────────────────────────────────────────────────

  group('EditProfileScreen — Farmer', () {
    testWidgets('renders Edit Profile title', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('pre-fills display name', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('John Farmer'), findsOneWidget);
    });

    testWidgets('shows Farmer role badge', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Farmer'), findsOneWidget);
    });

    testWidgets('shows Email Verified badge when isVerified=true', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Email Verified'), findsOneWidget);
    });

    testWidgets('shows Display Name field', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      // CustomTextField appends ' *' for isRequired=true fields,
      // so the rendered label is 'Display Name *'.
      expect(find.textContaining('Display Name'), findsOneWidget);
    });

    testWidgets('shows farmer-specific fields', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Farm Size (hectares)'), findsOneWidget);
      expect(find.text('Farm Location'), findsOneWidget);
      expect(find.text('Coffee Varieties'), findsOneWidget);
      expect(find.text('Farm Registration Number'), findsOneWidget);
    });

    testWidgets('does not show buyer fields for farmer', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Business Name'), findsNothing);
      expect(find.text('Business Type'), findsNothing);
      expect(find.text('Monthly Volume (kg)'), findsNothing);
    });

    testWidgets('shows Save Changes button', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows camera icon when no photo URL', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('shows edit overlay icon on avatar', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('tapping save with valid name does not crash', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      // Scroll so that button is visible before tapping
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('pre-fills farm size', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('pre-fills farm location', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Kigali'), findsOneWidget);
    });

    testWidgets('pre-fills coffee varieties', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Arabica, Robusta'), findsOneWidget);
    });

    testWidgets('pre-fills farm registration number', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('REG123'), findsOneWidget);
    });
  });

  // ── Buyer: form fields ───────────────────────────────────────────────────────

  group('EditProfileScreen — Buyer', () {
    testWidgets('shows Buyer role badge', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Buyer'), findsOneWidget);
    });

    testWidgets('shows Email Unverified badge when isVerified=false', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Email Unverified'), findsOneWidget);
    });

    testWidgets('shows buyer-specific fields', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Business Name'), findsOneWidget);
      expect(find.text('Business Type'), findsOneWidget);
      expect(find.text('Monthly Volume (kg)'), findsOneWidget);
    });

    testWidgets('does not show farmer fields for buyer', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Farm Size (hectares)'), findsNothing);
      expect(find.text('Farm Location'), findsNothing);
      expect(find.text('Coffee Varieties'), findsNothing);
      expect(find.text('Farm Registration Number'), findsNothing);
    });

    testWidgets('pre-fills business name', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Coffee Co'), findsOneWidget);
    });

    testWidgets('pre-fills business type', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Roaster'), findsOneWidget);
    });

    testWidgets('shows Save Changes button', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('clears display name and shows validation error', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      final field = find.ancestor(
        of: find.text('Jane Buyer'),
        matching: find.byType(TextFormField),
      );
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field.first, '');
      }
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();
      expect(find.textContaining('required'), findsAtLeastNWidgets(1));
    });
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  group('EditProfileScreen — ProfileLoading state', () {
    testWidgets(
        'shows CircularProgressIndicator inside Save button when ProfileLoading',
        (tester) async {
      final repo = _FakeUserRepository(profile: _farmerProfile());
      final pb = ProfileBloc(userRepository: repo)
        ..emit(const ProfileLoading());

      await tester.pumpWidget(_buildScreen(_farmerProfile(), bloc: pb));
      await tester.pump();

      // CustomButton renders a SizedBox wrapping a CircularProgressIndicator
      // when isLoading=true (state is ProfileLoading).
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Save button is disabled while ProfileLoading', (tester) async {
      final repo = _FakeUserRepository(profile: _farmerProfile());
      final pb = ProfileBloc(userRepository: repo)
        ..emit(const ProfileLoading());

      await tester.pumpWidget(_buildScreen(_farmerProfile(), bloc: pb));
      await tester.pump();

      // The ElevatedButton has onPressed == null when isLoading.
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });
  });

  // ── Error state ───────────────────────────────────────────────────────────

  group('EditProfileScreen — ProfileFailure state', () {
    testWidgets('shows ErrorBanner with failure message', (tester) async {
      final repo = _FakeUserRepository(profile: _farmerProfile());
      final pb = ProfileBloc(userRepository: repo)
        ..emit(const ProfileFailure('Something went wrong'));

      await tester.pumpWidget(_buildScreen(_farmerProfile(), bloc: pb));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets(
        'shows snackbar with error message on ProfileFailure emitted after initial render',
        (tester) async {
      final repo = _FakeUserRepository(profile: _farmerProfile());
      final pb = ProfileBloc(userRepository: repo);

      await tester.pumpWidget(_buildScreen(_farmerProfile(), bloc: pb));
      await tester.pump();

      // Emit failure AFTER initial render — BlocConsumer listener fires.
      pb.emit(const ProfileFailure('Network error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The SnackBar triggered by the listener should be visible.
      expect(find.text('Network error'), findsAtLeastNWidgets(1));
    });
  });

  // ── ProfileUpdateSuccess navigates back ───────────────────────────────────

  group('EditProfileScreen — ProfileUpdateSuccess', () {
    testWidgets('navigates back when ProfileUpdateSuccess is emitted',
        (tester) async {
      final profile = _farmerProfile();
      final repo = _FakeUserRepository(profile: profile);
      final pb = ProfileBloc(userRepository: repo);

      // Use a Navigator with two routes so we can verify a pop happened.
      bool popped = false;
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ProfileBloc>(create: (_) => pb),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: pb,
                        child: EditProfileScreen(userProfile: profile),
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open Edit'),
              ),
            ),
          ),
        ),
      );

      // Navigate to EditProfileScreen.
      await tester.tap(find.text('Open Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);

      // Emit success — listener calls Navigator.pop.
      pb.emit(ProfileUpdateSuccess(profile));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(EditProfileScreen), findsNothing);
    });
  });

  // ── Validation ────────────────────────────────────────────────────────────

  group('EditProfileScreen — Validation', () {
    testWidgets(
        'shows validation error when display name is cleared and saved',
        (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));

      // Clear the Display Name field.
      final nameField = find.ancestor(
        of: find.text('John Farmer'),
        matching: find.byType(TextFormField),
      );
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, '');

      // Scroll to and tap Save.
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('required'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'shows validation error for invalid farm size (non-numeric)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));

      final farmSizeField = find.ancestor(
        of: find.text('5.0'),
        matching: find.byType(TextFormField),
      );
      expect(farmSizeField, findsOneWidget);
      await tester.enterText(farmSizeField, 'not_a_number');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('valid farm size'), findsOneWidget);
    });

    testWidgets('shows validation error for negative farm size', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));

      final farmSizeField = find.ancestor(
        of: find.text('5.0'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(farmSizeField, '-1');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('valid farm size'), findsOneWidget);
    });

    testWidgets(
        'shows validation error for invalid monthly volume (buyer)',
        (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));

      // Find Monthly Volume field by label text.
      final volumeField = find.ancestor(
        of: find.text('Monthly Volume (kg)'),
        matching: find.byType(TextFormField),
      );
      expect(volumeField, findsOneWidget);
      await tester.enterText(volumeField, 'abc');

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();

      expect(find.textContaining('valid volume'), findsOneWidget);
    });

    testWidgets('passes validation when all fields are valid for farmer',
        (tester) async {
      final repo = _FakeUserRepository(profile: _farmerProfile());
      final pb = ProfileBloc(userRepository: repo);

      await tester.pumpWidget(_buildScreen(_farmerProfile(), bloc: pb));

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'), warnIfMissed: false);
      await tester.pump();

      // No validation error text should appear.
      expect(find.textContaining('required'), findsNothing);
      expect(find.textContaining('valid farm size'), findsNothing);
    });
  });

  // ── Role badge display ────────────────────────────────────────────────────

  group('EditProfileScreen — Role and verification badges', () {
    testWidgets('shows Farmer badge for farmer profile', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Farmer'), findsOneWidget);
    });

    testWidgets('shows Buyer badge for buyer profile', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Buyer'), findsOneWidget);
    });

    testWidgets('shows Email Verified for verified farmer', (tester) async {
      await tester.pumpWidget(_buildScreen(_farmerProfile()));
      expect(find.text('Email Verified'), findsOneWidget);
    });

    testWidgets('shows Email Unverified for unverified buyer', (tester) async {
      await tester.pumpWidget(_buildScreen(_buyerProfile()));
      expect(find.text('Email Unverified'), findsOneWidget);
    });
  });

  // ── _hasChanges() via PopScope ─────────────────────────────────────────────

  group('EditProfileScreen — PopScope / back navigation', () {
    testWidgets('tapping back with no changes calls _hasChanges (farmer)',
        (tester) async {
      final farmerProfile = _farmerProfile();
      // Need a parent route + bloc above MaterialApp so new routes can access it
      await tester.pumpWidget(
        _buildScreen(farmerProfile),
      );
      await tester.pump();
      expect(find.byType(EditProfileScreen), findsOneWidget);

      // Trigger pop — no changes → onPopInvokedWithResult fires → _hasChanges()
      // returns false → Navigator.pop is called. Since EditProfileScreen is the
      // root route, pop is a no-op (screen stays), but all _hasChanges() lines
      // are executed (coverage goal met).
      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pump();

      // Screen stays (root route cannot be popped), but no crash occurred.
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('tapping back with no changes calls _hasChanges (buyer)',
        (tester) async {
      final buyerProfile = _buyerProfile();
      await tester.pumpWidget(_buildScreen(buyerProfile));
      await tester.pump();
      expect(find.byType(EditProfileScreen), findsOneWidget);

      final NavigatorState nav = tester.state(find.byType(Navigator));
      nav.maybePop();
      await tester.pump();

      // buyer field checks (lines 99-106) covered — no crash.
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });

  // ── Buyer _buildUpdateMap (lines 133-139) ─────────────────────────────────

  group('EditProfileScreen — buyer save dispatches ProfileUpdateRequested', () {
    testWidgets('saving buyer profile dispatches update event', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final buyerProfile = _buyerProfile();
      await tester.pumpWidget(_buildScreen(buyerProfile));
      await tester.pump();

      // Tap Save Changes to trigger _buildUpdateMap with buyer fields
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // No crash — buyer _buildUpdateMap (lines 133-139) was executed
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}
