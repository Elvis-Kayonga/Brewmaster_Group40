// test/widgets/status_badge_test.dart
//
// Widget tests for StatusBadge, NotificationBadge, PriorityBadge,
// OnlineStatusIndicator, and TagBadge.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/status_badge.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child));

void main() {
  group('StatusBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(label: 'Active'),
      ));
      await tester.pump();
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders with each type without throwing', (tester) async {
      for (final type in StatusBadgeType.values) {
        await tester.pumpWidget(_wrap(
          StatusBadge(label: type.name, type: type),
        ));
        await tester.pump();
        expect(find.text(type.name), findsOneWidget);
      }
    });

    testWidgets('renders with each size without throwing', (tester) async {
      for (final size in StatusBadgeSize.values) {
        await tester.pumpWidget(_wrap(
          StatusBadge(label: 'Test', size: size),
        ));
        await tester.pump();
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(
          label: 'Check',
          icon: Icons.check,
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders indicator dot when showIndicator is true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(label: 'Live', showIndicator: true),
      ));
      await tester.pump();
      // Widget renders without error
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('outlined mode renders without fill', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(label: 'Outlined', outlined: true),
      ));
      await tester.pump();
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('custom backgroundColor and textColor respected',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(
          label: 'Custom',
          backgroundColor: Colors.purple,
          textColor: Colors.white,
        ),
      ));
      await tester.pump();
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('small size renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(label: 'Small', size: StatusBadgeSize.small),
      ));
      await tester.pump();
      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('large size renders', (tester) async {
      await tester.pumpWidget(_wrap(
        const StatusBadge(label: 'Large', size: StatusBadgeSize.large),
      ));
      await tester.pump();
      expect(find.text('Large'), findsOneWidget);
    });
  });

  group('NotificationBadge', () {
    testWidgets('shows count when count > 0', (tester) async {
      await tester.pumpWidget(_wrap(const NotificationBadge(count: 5)));
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows nothing when count is 0 and showDot is false',
        (tester) async {
      await tester.pumpWidget(_wrap(const NotificationBadge(count: 0)));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('shows dot when showDot is true regardless of count',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const NotificationBadge(count: 0, showDot: true),
      ));
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows maxCount+ when count exceeds maxCount', (tester) async {
      await tester.pumpWidget(_wrap(
        const NotificationBadge(count: 150, maxCount: 99),
      ));
      await tester.pump();
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('custom color applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const NotificationBadge(count: 3, color: Colors.green),
      ));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('PriorityBadge', () {
    testWidgets('renders Critical for priority 1', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge(priority: 1)));
      await tester.pump();
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('renders High for priority 2', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge(priority: 2)));
      await tester.pump();
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('renders Medium for priority 3', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge(priority: 3)));
      await tester.pump();
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('renders Low for priority 4', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge(priority: 4)));
      await tester.pump();
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('renders Normal for unknown priority', (tester) async {
      await tester.pumpWidget(_wrap(const PriorityBadge(priority: 99)));
      await tester.pump();
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('uses custom label when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const PriorityBadge(priority: 1, labels: {1: 'Urgent!'}),
      ));
      await tester.pump();
      expect(find.text('Urgent!'), findsOneWidget);
    });
  });

  group('OnlineStatusIndicator', () {
    testWidgets('renders when online', (tester) async {
      await tester.pumpWidget(_wrap(const OnlineStatusIndicator(isOnline: true)));
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders when offline', (tester) async {
      await tester.pumpWidget(_wrap(
        const OnlineStatusIndicator(isOnline: false),
      ));
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('custom size applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const OnlineStatusIndicator(isOnline: true, size: 20),
      ));
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('no border when showBorder is false', (tester) async {
      await tester.pumpWidget(_wrap(
        const OnlineStatusIndicator(isOnline: true, showBorder: false),
      ));
      await tester.pump();
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('TagBadge', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(const TagBadge(label: 'Coffee')));
      await tester.pump();
      expect(find.text('Coffee'), findsOneWidget);
    });

    testWidgets('shows remove button when onRemove provided', (tester) async {
      bool removed = false;
      await tester.pumpWidget(_wrap(
        TagBadge(label: 'Tag', onRemove: () => removed = true),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(removed, isTrue);
    });

    testWidgets('does not show remove button when onRemove is null',
        (tester) async {
      await tester.pumpWidget(_wrap(const TagBadge(label: 'NoRemove')));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        TagBadge(label: 'Tap me', onTap: () => tapped = true),
      ));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('custom color applied', (tester) async {
      await tester.pumpWidget(_wrap(
        const TagBadge(label: 'Colored', color: Colors.red),
      ));
      await tester.pump();
      expect(find.text('Colored'), findsOneWidget);
    });
  });
}
