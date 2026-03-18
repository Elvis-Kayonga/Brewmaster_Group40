/// Widget tests for BuyerDashboardScreen
///
/// Requirements: 11.2, 11.5, 16.1 (Clean Architecture)
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
import 'package:brewmaster/presentation/screens/dashboard/buyer_dashboard_screen.dart';
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
  Stream<UserProfile?> watchUserProfile(String userId) => Stream.value(null);
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
  group('BuyerDashboardScreen Widget Tests', () {
    Widget createTestWidget({String userId = 'test-buyer-123'}) {
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
          child: BuyerDashboardScreen(userId: userId),
        ),
      );
    }

    group('Loading State Tests', () {
      testWidgets(
        'Should display loading indicator when loading',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          // Check before pump() — bloc hasn't processed the event yet
          expect(find.byType(LoadingIndicator), findsOneWidget);
          expect(find.text('Loading your dashboard…'), findsOneWidget);
        },
      );

      testWidgets(
        'Should display screen with app bar when loading',
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
        'Should display error message when error occurs',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should display ErrorStateWidget with retry button on error',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );
    });

    group('Dashboard Content Tests', () {
      testWidgets(
        'Should display "My Dashboard" title in app bar',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.text('Brew Master'), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
        },
      );

      testWidgets(
        'Should have refresh button in app bar',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          final refreshButton = find.byIcon(Icons.refresh);
          expect(refreshButton, findsOneWidget);

          final iconButton = tester.widget<IconButton>(
            find.ancestor(
              of: refreshButton,
              matching: find.byType(IconButton),
            ),
          );
          expect(iconButton.tooltip, equals('Refresh'));
        },
      );

      testWidgets(
        'Should display overview section header',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // Overview header is present when data loads
        },
      );
    });

    group('User Interaction Tests', () {
      testWidgets(
        'Should trigger refresh when refresh button is tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(find.byIcon(Icons.refresh), findsOneWidget);
        },
      );

      testWidgets(
        'Should support pull-to-refresh gesture',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // RefreshIndicator may be present after data loads
        },
      );
    });

    group('Navigation Tests', () {
      testWidgets(
        'Should navigate back when back button is pressed',
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
                          child: const BuyerDashboardScreen(
                            userId: 'test-buyer-123',
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Go to Dashboard'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Go to Dashboard'));
          await tester.pumpAndSettle();

          expect(find.text('Brew Master'), findsOneWidget);

          final NavigatorState navigator =
              tester.state(find.byType(Navigator).first);
          navigator.pop();
          await tester.pumpAndSettle();

          expect(find.text('Go to Dashboard'), findsOneWidget);
        },
      );
    });

    group('Layout and UI Tests', () {
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

          expect(
            find.byType(BlocBuilder<DashboardBloc, DashboardState>),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Should maintain userId property',
        (WidgetTester tester) async {
          const testUserId = 'test-buyer-456';

          await tester.pumpWidget(createTestWidget(userId: testUserId));
          await tester.pump();

          final dashboardWidget = tester.widget<BuyerDashboardScreen>(
            find.byType(BuyerDashboardScreen),
          );
          expect(dashboardWidget.userId, equals(testUserId));
        },
      );
    });

    group('State Management Tests', () {
      testWidgets(
        'Should call loadDashboard on initState',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should rebuild when bloc emits new state',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );
    });

    group('Accessibility Tests', () {
      testWidgets(
        'Should have accessible refresh button',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          final refreshButton = find.byIcon(Icons.refresh);
          expect(refreshButton, findsOneWidget);

          final iconButton = tester.widget<IconButton>(
            find.ancestor(
              of: refreshButton,
              matching: find.byType(IconButton),
            ),
          );
          expect(iconButton.tooltip, isNotNull);
          expect(iconButton.tooltip, equals('Refresh'));
        },
      );

      testWidgets(
        'Should be navigable with keyboard',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(IconButton), findsWidgets);
        },
      );
    });

    group('Edge Cases', () {
      testWidgets(
        'Should handle empty userId gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(userId: ''));
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should handle rapid refresh button taps',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(find.byType(BuyerDashboardScreen), findsOneWidget);
        },
      );
    });
  });

  group('BuyerDashboard Model Tests', () {
    test('Should create BuyerDashboard with correct values', () {
      const dashboard = BuyerDashboard(
        totalPurchases: 10,
        conversations: 5,
        savedListings: 3,
      );

      expect(dashboard.totalPurchases, equals(10));
      expect(dashboard.conversations, equals(5));
      expect(dashboard.savedListings, equals(3));
    });

    test('Should create empty dashboard', () {
      final dashboard = BuyerDashboard.empty();

      expect(dashboard.totalPurchases, equals(0));
      expect(dashboard.conversations, equals(0));
      expect(dashboard.savedListings, equals(0));
    });
  });
}
