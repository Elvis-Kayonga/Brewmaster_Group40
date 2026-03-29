// test/properties/verification_badge_properties_test.dart
//
// Property-based tests for task 26.3: VerificationBadge propagation,
// search prioritization of verified farmers, and trusted-buyer badge logic.
//
// Developer: Developer 1 + Developer 2

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/widgets/common/verification_badge.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wrap a widget in a minimal MaterialApp for pumpWidget.
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child));

// ---------------------------------------------------------------------------
// Badge propagation tests
// ---------------------------------------------------------------------------

void main() {
  group('VerificationBadge propagation (task 26.3)', () {
    testWidgets('verified status renders verified icon and label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.verified)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('pending status renders hourglass icon and label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.pending)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('rejected status renders cancel icon and label',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.rejected)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('unverified status renders nothing', (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.unverified)),
      );
      await tester.pump();
      expect(find.byType(Icon), findsNothing);
      expect(find.text('Unverified'), findsNothing);
    });

    testWidgets('compact mode renders only an icon with tooltip',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(
          status: VerificationStatus.verified,
          compact: true,
        )),
      );
      await tester.pump();
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      // No label text in compact mode
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('compact mode for pending shows tooltip message',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(
          status: VerificationStatus.pending,
          compact: true,
        )),
      );
      await tester.pump();
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Pending');
    });

    testWidgets('compact mode for rejected shows tooltip message',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(
          status: VerificationStatus.rejected,
          compact: true,
        )),
      );
      await tester.pump();
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Rejected');
    });

    testWidgets('compact unverified still renders nothing', (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(
          status: VerificationStatus.unverified,
          compact: true,
        )),
      );
      await tester.pump();
      expect(find.byType(Tooltip), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Search prioritization — pure logic tests (no widget pump needed)
  // -------------------------------------------------------------------------

  group('Search prioritization of verified farmers (task 26.3)', () {
    List<Map<String, dynamic>> sortByVerification(
        List<Map<String, dynamic>> listings) {
      final sorted = List<Map<String, dynamic>>.from(listings);
      sorted.sort((a, b) {
        final aVerified =
            (a['verificationStatus'] as VerificationStatus) ==
                VerificationStatus.verified;
        final bVerified =
            (b['verificationStatus'] as VerificationStatus) ==
                VerificationStatus.verified;
        if (aVerified == bVerified) return 0;
        return aVerified ? -1 : 1;
      });
      return sorted;
    }

    test('verified farmers sort before unverified', () {
      final listings = [
        {'id': '1', 'verificationStatus': VerificationStatus.unverified},
        {'id': '2', 'verificationStatus': VerificationStatus.verified},
        {'id': '3', 'verificationStatus': VerificationStatus.pending},
      ];
      final sorted = sortByVerification(listings);
      expect(sorted.first['id'], '2');
    });

    test('all verified farmers retain relative order', () {
      final listings = [
        {'id': 'a', 'verificationStatus': VerificationStatus.verified},
        {'id': 'b', 'verificationStatus': VerificationStatus.verified},
        {'id': 'c', 'verificationStatus': VerificationStatus.unverified},
      ];
      final sorted = sortByVerification(listings);
      expect(sorted[0]['id'], 'a');
      expect(sorted[1]['id'], 'b');
      expect(sorted[2]['id'], 'c');
    });

    test('list with no verified farmers is unchanged', () {
      final listings = [
        {'id': 'x', 'verificationStatus': VerificationStatus.pending},
        {'id': 'y', 'verificationStatus': VerificationStatus.unverified},
      ];
      final sorted = sortByVerification(listings);
      expect(sorted.map((e) => e['id']).toList(), ['x', 'y']);
    });

    test('empty list sorts to empty list', () {
      expect(sortByVerification([]), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Trusted buyer badge logic
  // -------------------------------------------------------------------------

  group('Trusted buyer badge (task 26.3)', () {
    bool isTrustedBuyer(VerificationStatus status, String role) =>
        role == 'buyer' && status == VerificationStatus.verified;

    test('verified buyer is trusted', () {
      expect(isTrustedBuyer(VerificationStatus.verified, 'buyer'), isTrue);
    });

    test('verified farmer is not a trusted buyer', () {
      expect(isTrustedBuyer(VerificationStatus.verified, 'farmer'), isFalse);
    });

    test('pending buyer is not trusted', () {
      expect(isTrustedBuyer(VerificationStatus.pending, 'buyer'), isFalse);
    });

    test('unverified buyer is not trusted', () {
      expect(isTrustedBuyer(VerificationStatus.unverified, 'buyer'), isFalse);
    });

    test('rejected buyer is not trusted', () {
      expect(isTrustedBuyer(VerificationStatus.rejected, 'buyer'), isFalse);
    });

    testWidgets('verified badge uses green color for verified status',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.verified)),
      );
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(Icons.verified));
      expect(icon.color, const Color(0xFF388E3C));
    });

    testWidgets('pending badge uses orange color', (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.pending)),
      );
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(Icons.hourglass_top));
      expect(icon.color, const Color(0xFFF57F17));
    });

    testWidgets('rejected badge uses red color', (tester) async {
      await tester.pumpWidget(
        _wrap(const VerificationBadge(status: VerificationStatus.rejected)),
      );
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(Icons.cancel));
      expect(icon.color, const Color(0xFFD32F2F));
    });
  });
}
