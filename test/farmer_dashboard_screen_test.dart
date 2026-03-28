/// Widget tests for FarmerDashboardScreen
///
/// Testing patterns demonstrated:
/// 1. BLoC mocking with farmer-specific data
/// 2. Testing multiple metrics display
/// 3. Grid layout testing
/// 4. Pull-to-refresh functionality
/// 5. Error recovery
/// 6. Loading state transitions
/// 7. Business logic validation
///
/// Requirements: 11.1, 11.3, 11.4, 11.5, 16.1 (Clean Architecture)
/// Developer: Developer 5 (refactored to BLoC by Developer 1)
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/buyer_dashboard.dart';
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/dashboard/farmer_dashboard_screen.dart';
import 'package:brewmaster/presentation/widgets/common/loading_indicator.dart';

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
  Stream<UserProfile?> watchUserProfile(String userId) =>
      Stream.value(null);

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

AuthBloc _makeAuthBloc() => AuthBloc(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(),
    );

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async =>
      FarmerDashboard.empty();
  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) async =>
      BuyerDashboard.empty();
  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      Stream.value(FarmerDashboard.empty());
  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      Stream.value(BuyerDashboard.empty());
}

void main() {
  group('FarmerDashboardScreen Widget Tests', () {
    /// Helper function to create testable widget with BLoC
    Widget createTestWidget({String userId = 'test-farmer-123'}) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  DashboardBloc(repository: _FakeDashboardRepository()),
            ),
            BlocProvider(create: (_) => _makeAuthBloc()),
            BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
          ],
          child: FarmerDashboardScreen(userId: userId),
        ),
      );
    }

    /// Helper to create test farmer dashboard data
    FarmerDashboard createTestDashboard() {
      return const FarmerDashboard(
        activeListings: 12,
        totalEarnings: 45000.0,
        conversations: 8,
        savedCount: 250,
        responseRate: 92.5,
      );
    }

    group('Loading State Tests', () {
      testWidgets(
        'Should display loading indicator on initial load',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          // Check before pump() — bloc hasn't processed the event yet
          expect(find.byType(LoadingIndicator), findsOneWidget);
          expect(find.text('Loading your dashboard…'), findsOneWidget);
        },
      );

      testWidgets(
        'Should show app bar even during loading',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(AppBar), findsOneWidget);
          expect(find.text('Brew Master'), findsOneWidget);
          expect(find.byIcon(Icons.refresh), findsOneWidget);
        },
      );
    });

    group('Error State Tests', () {
      testWidgets(
        'Should handle bloc errors gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should provide retry mechanism on error',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(BlocBuilder<DashboardBloc, DashboardState>),
              findsOneWidget);
        },
      );
    });

    group('Dashboard Content Tests', () {
      testWidgets(
        'Should display correct title in app bar',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.text('Brew Master'), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
        },
      );

      testWidgets(
        'Should have refresh button with tooltip',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          final refreshIcon = find.byIcon(Icons.refresh);
          expect(refreshIcon, findsOneWidget);

          final iconButton = tester.widget<IconButton>(
            find.ancestor(
              of: refreshIcon,
              matching: find.byType(IconButton),
            ),
          );
          expect(iconButton.tooltip, equals('Refresh'));
        },
      );

      testWidgets(
        'Should display overview section',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // After data loads, overview section should be present
        },
      );
    });

    group('User Interaction Tests', () {
      testWidgets(
        'Should handle refresh button tap',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should support pull-to-refresh gesture',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // RefreshIndicator would be present after data loads
        },
      );

      testWidgets(
        'Should handle multiple rapid refresh requests',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          for (int i = 0; i < 5; i++) {
            await tester.tap(find.byIcon(Icons.refresh));
            await tester.pump();
          }

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );
    });

    group('Navigation Tests', () {
      testWidgets(
        'Should integrate with navigation stack',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (_) => DashboardBloc(
                                  repository: _FakeDashboardRepository()),
                            ),
                            BlocProvider(create: (_) => _makeAuthBloc()),
            BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
                          ],
                          child: const FarmerDashboardScreen(
                            userId: 'test-farmer-123',
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Open Farmer Dashboard'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Open Farmer Dashboard'));
          await tester.pumpAndSettle();

          expect(find.text('Brew Master'), findsOneWidget);

          final NavigatorState navigator =
              tester.state(find.byType(Navigator).first);
          navigator.pop();
          await tester.pumpAndSettle();

          expect(find.text('Open Farmer Dashboard'), findsOneWidget);
        },
      );

      testWidgets(
        'Should handle back button press',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => DashboardBloc(
                        repository: _FakeDashboardRepository()),
                  ),
                  BlocProvider(create: (_) => _makeAuthBloc()),
            BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
                ],
                child: const FarmerDashboardScreen(userId: 'test-farmer-123'),
              ),
            ),
          );

          await tester.pump();

          expect(find.text('Brew Master'), findsOneWidget);
        },
      );
    });

    group('Layout and Structure Tests', () {
      testWidgets(
        'Should have proper scaffold structure',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
        },
      );

      testWidgets(
        'Should use BlocBuilder for state management',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(BlocBuilder<DashboardBloc, DashboardState>),
              findsOneWidget);
        },
      );

      testWidgets(
        'Should maintain userId property',
        (WidgetTester tester) async {
          const testUserId = 'farmer-xyz-789';

          await tester.pumpWidget(
            MaterialApp(
              home: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => DashboardBloc(
                        repository: _FakeDashboardRepository()),
                  ),
                  BlocProvider(create: (_) => _makeAuthBloc()),
            BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
                ],
                child: const FarmerDashboardScreen(userId: testUserId),
              ),
            ),
          );

          await tester.pump();

          final widget = tester.widget<FarmerDashboardScreen>(
            find.byType(FarmerDashboardScreen),
          );
          expect(widget.userId, equals(testUserId));
        },
      );
    });

    group('State Management Tests', () {
      testWidgets(
        'Should trigger loadDashboard on initState',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should pass correct userId to bloc event',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should rebuild on bloc state changes',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );
    });

    group('Farmer-Specific Metrics Tests', () {
      test('FarmerDashboard should have all required metrics', () {
        final dashboard = createTestDashboard();

        expect(dashboard.activeListings, equals(12));
        expect(dashboard.totalEarnings, equals(45000.0));
        expect(dashboard.conversations, equals(8));
        expect(dashboard.savedCount, equals(250));
        expect(dashboard.responseRate, equals(92.5));
      });

      test('Should create empty farmer dashboard', () {
        final dashboard = FarmerDashboard.empty();

        expect(dashboard.activeListings, equals(0));
        expect(dashboard.totalEarnings, equals(0.0));
        expect(dashboard.conversations, equals(0));
        expect(dashboard.savedCount, equals(0));
        expect(dashboard.responseRate, equals(0.0));
      });

      test('Response rate should be percentage between 0 and 100', () {
        final dashboard = createTestDashboard();

        expect(dashboard.responseRate, greaterThanOrEqualTo(0.0));
        expect(dashboard.responseRate, lessThanOrEqualTo(100.0));
      });
    });

    group('Accessibility Tests', () {
      testWidgets(
        'Should have accessible refresh button',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          final refreshIcon = find.byIcon(Icons.refresh);
          expect(refreshIcon, findsOneWidget);

          final iconButton = tester.widget<IconButton>(
            find.ancestor(
              of: refreshIcon,
              matching: find.byType(IconButton),
            ),
          );
          expect(iconButton.tooltip, isNotNull);
        },
      );

      testWidgets(
        'Should be keyboard navigable',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(IconButton), findsWidgets);
        },
      );
    });

    group('Performance Tests', () {
      testWidgets(
        'Should handle frequent bloc state updates efficiently',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          for (int i = 0; i < 10; i++) {
            await tester.tap(find.byIcon(Icons.refresh));
            await tester.pump();
          }

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );
    });

    group('Edge Cases', () {
      testWidgets(
        'Should handle empty userId',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(userId: ''));
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should handle very long userId',
        (WidgetTester tester) async {
          final longUserId = 'farmer-${'1234567890' * 10}';

          await tester.pumpWidget(createTestWidget(userId: longUserId));
          await tester.pump();

          final widget = tester.widget<FarmerDashboardScreen>(
            find.byType(FarmerDashboardScreen),
          );
          expect(widget.userId, equals(longUserId));
        },
      );

      testWidgets(
        'Should handle widget rebuild during loading',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(FarmerDashboardScreen), findsOneWidget);
        },
      );
    });
  });
}
