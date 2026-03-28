// test/widgets/error_state_widget_test.dart
//
// Widget tests for ErrorStateWidget and its specialised variants.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorStateWidget', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(message: 'Something went wrong'),
      ));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(
          message: 'Msg',
          title: 'Error Title',
        ),
      ));
      expect(find.text('Error Title'), findsOneWidget);
      expect(find.text('Msg'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Error',
          onRetry: () => retried = true,
        ),
      ));
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(message: 'Error'),
      ));
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('shows secondary action button', (tester) async {
      bool secondaryTapped = false;
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Error',
          onRetry: () {},
          secondaryActionText: 'Go back',
          onSecondaryAction: () => secondaryTapped = true,
        ),
      ));
      expect(find.text('Go back'), findsOneWidget);
      await tester.tap(find.text('Go back'));
      await tester.pump();
      expect(secondaryTapped, isTrue);
    });

    testWidgets('compact layout renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(message: 'Compact error', compact: true),
      ));
      expect(find.text('Compact error'), findsOneWidget);
    });

    testWidgets('expandable details shown when enabled', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(
          message: 'Error',
          details: 'Stack trace here',
          showExpandableDetails: true,
        ),
      ));
      expect(find.text('Show details'), findsOneWidget);
    });

    testWidgets('custom icon rendered', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(
          message: 'Error',
          icon: Icons.wifi_off,
        ),
      ));
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('custom icon color applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorStateWidget(
          message: 'Error',
          iconColor: Colors.orange,
        ),
      ));
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('custom retry text used', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Error',
          retryText: 'Refresh',
          onRetry: () {},
        ),
      ));
      expect(find.text('Refresh'), findsOneWidget);
    });
  });

  group('NetworkErrorWidget', () {
    testWidgets('renders connection error message', (tester) async {
      await tester.pumpWidget(_wrap(const NetworkErrorWidget()));
      expect(find.text('Connection error'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_wrap(
        NetworkErrorWidget(onRetry: () => retried = true),
      ));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('compact mode renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const NetworkErrorWidget(compact: true),
      ));
      expect(find.text('Connection error'), findsOneWidget);
    });
  });

  group('ServerErrorWidget', () {
    testWidgets('renders server error message', (tester) async {
      await tester.pumpWidget(_wrap(const ServerErrorWidget()));
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('shows error code in expandable details', (tester) async {
      await tester.pumpWidget(_wrap(
        const ServerErrorWidget(errorCode: '500'),
      ));
      expect(find.text('Show details'), findsOneWidget);
    });

    testWidgets('no expandable details when errorCode is null', (tester) async {
      await tester.pumpWidget(_wrap(const ServerErrorWidget()));
      expect(find.text('Show details'), findsNothing);
    });
  });

  group('PermissionErrorWidget', () {
    testWidgets('renders permission required title', (tester) async {
      await tester.pumpWidget(_wrap(const PermissionErrorWidget()));
      expect(find.text('Permission required'), findsOneWidget);
    });

    testWidgets('shows permission name when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const PermissionErrorWidget(permissionName: 'Camera'),
      ));
      expect(find.textContaining('Camera'), findsOneWidget);
    });

    testWidgets('shows grant permission button', (tester) async {
      bool granted = false;
      await tester.pumpWidget(_wrap(
        PermissionErrorWidget(onRequestPermission: () => granted = true),
      ));
      await tester.tap(find.text('Grant permission'));
      await tester.pump();
      expect(granted, isTrue);
    });
  });

  group('AuthErrorWidget', () {
    testWidgets('renders session expired message', (tester) async {
      await tester.pumpWidget(_wrap(const AuthErrorWidget()));
      expect(find.text('Session expired'), findsOneWidget);
    });

    testWidgets('shows sign in button when onLogin provided', (tester) async {
      bool loggedIn = false;
      await tester.pumpWidget(_wrap(
        AuthErrorWidget(onLogin: () => loggedIn = true),
      ));
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(loggedIn, isTrue);
    });
  });

  group('ErrorBanner', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorBanner(message: 'Failed to load'),
      ));
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(_wrap(
        ErrorBanner(
          message: 'Error',
          onRetry: () => retried = true,
        ),
      ));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('shows dismiss button when onDismiss provided', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(_wrap(
        ErrorBanner(
          message: 'Error',
          onDismiss: () => dismissed = true,
        ),
      ));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('no buttons when no callbacks provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorBanner(message: 'Error'),
      ));
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
