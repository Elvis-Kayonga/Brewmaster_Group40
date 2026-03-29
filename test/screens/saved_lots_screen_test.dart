// Widget tests for SavedLotsScreen.
// Coverage: empty state, loaded with items, Clear All action, remove item,
// message button, pay button navigation, multiple items, farmer name display.


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/saved_lot.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/saved_lots/saved_lots_bloc.dart';
import 'package:brewmaster/presentation/screens/saved_lots/saved_lots_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

SavedLot _makeLot({
  String listingId = 'lot-1',
  String farmerId = 'farmer-1',
  String? farmerName = 'John Farmer',
  String variety = 'Arabica',
  double pricePerKg = 5.50,
  double availableQuantity = 200,
  String location = 'Ethiopia',
  String? imageUrl,
}) =>
    SavedLot(
      listingId: listingId,
      farmerId: farmerId,
      farmerName: farmerName,
      variety: variety,
      pricePerKg: pricePerKg,
      availableQuantity: availableQuantity,
      location: location,
      imageUrl: imageUrl,
      savedAt: DateTime(2024, 1, 1),
    );

// ── Helper ────────────────────────────────────────────────────────────────────

/// Wraps [SavedLotsScreen] with all required blocs.
/// [initialLots] are added to the bloc before the widget tree is built so the
/// screen renders in a loaded state immediately.
Widget _wrap({List<SavedLot> initialLots = const []}) {
  // Providers above MaterialApp so new routes (e.g. PaymentScreen) can access them.
  return MultiBlocProvider(
    providers: [
      BlocProvider<SavedLotsBloc>(
        create: (_) {
          final bloc = SavedLotsBloc(userRepository: FakeUserRepository());
          for (final lot in initialLots) {
            bloc.add(SavedLotAdded(lot));
          }
          return bloc;
        },
      ),
      BlocProvider<MessagingBloc>(
        create: (_) =>
            MessagingBloc(repository: FakeMessageRepository()),
      ),
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(
          authRepository: FakeAuthRepository(),
          userRepository: FakeUserRepository(),
        ),
      ),
      BlocProvider<PaymentBloc>(
        create: (_) => PaymentBloc(paymentRepository: FakePaymentRepository()),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SavedLotsScreen(),
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

  group('SavedLotsScreen', () {
    // ── App bar ──────────────────────────────────────────────────────────────

    testWidgets('shows "Saved Lots" title in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Saved Lots'), findsOneWidget);
    });

    testWidgets('does not show Clear All button when list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('Clear All'), findsNothing);
    });

    testWidgets('shows Clear All button when list has items', (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [_makeLot()]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Clear All'), findsOneWidget);
    });

    // ── Empty state ──────────────────────────────────────────────────────────

    testWidgets('shows empty state icon when no saved lots', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('shows "No saved lots yet" text when empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('No saved lots yet'), findsOneWidget);
    });

    testWidgets('shows hint text when empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(
        find.textContaining('Tap the heart on any listing'),
        findsOneWidget,
      );
    });

    // ── Loaded state — tile rendering ────────────────────────────────────────

    testWidgets('shows lot variety name', (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [_makeLot(variety: 'Gesha')]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Gesha'), findsOneWidget);
    });

    testWidgets('shows lot location in upper case', (tester) async {
      await tester.pumpWidget(
          _wrap(initialLots: [_makeLot(location: 'Kenya')]));
      await tester.pump();
      await tester.pump();
      expect(find.text('KENYA'), findsOneWidget);
    });

    testWidgets('shows price per kg', (tester) async {
      await tester.pumpWidget(
          _wrap(initialLots: [_makeLot(pricePerKg: 7.25)]));
      await tester.pump();
      await tester.pump();
      expect(find.text('\$7.25'), findsOneWidget);
    });

    testWidgets('shows available quantity', (tester) async {
      await tester.pumpWidget(
          _wrap(initialLots: [_makeLot(availableQuantity: 150)]));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('150'), findsOneWidget);
    });

    testWidgets('shows farmer name when provided', (tester) async {
      await tester.pumpWidget(
          _wrap(initialLots: [_makeLot(farmerName: 'Alice Grower')]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Alice Grower'), findsOneWidget);
    });

    testWidgets('does not show farmer name row when farmerName is null',
        (tester) async {
      await tester.pumpWidget(
          _wrap(initialLots: [_makeLot(farmerName: null)]));
      await tester.pump();
      await tester.pump();
      // The only text nodes visible should be the location, variety, etc.
      // A null farmerName means no extra Text widget with a farmer name.
      expect(find.text('null'), findsNothing);
    });

    testWidgets('shows Message and Direct Pay buttons on a tile',
        (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [_makeLot()]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Message'), findsOneWidget);
      expect(find.text('Direct Pay'), findsOneWidget);
    });

    testWidgets('shows placeholder image when imageUrl is null',
        (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [_makeLot(imageUrl: null)]));
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    // ── Multiple items ────────────────────────────────────────────────────────

    testWidgets('renders multiple saved lot tiles', (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [
        _makeLot(listingId: 'lot-1', variety: 'Arabica'),
        _makeLot(listingId: 'lot-2', variety: 'Robusta'),
      ]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Arabica'), findsOneWidget);
      expect(find.text('Robusta'), findsOneWidget);
    });

    // ── Clear All interaction ─────────────────────────────────────────────────

    testWidgets('tapping Clear All removes all items and shows empty state',
        (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [
        _makeLot(listingId: 'lot-1'),
        _makeLot(listingId: 'lot-2', variety: 'Robusta'),
      ]));
      await tester.pump();
      await tester.pump();

      // Confirm items are visible
      expect(find.text('Clear All'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // After clearing, empty state should show
      expect(find.text('No saved lots yet'), findsOneWidget);
      expect(find.text('Clear All'), findsNothing);
    });

    // ── Remove individual item ────────────────────────────────────────────────

    testWidgets('tapping favorite icon removes that lot from the list',
        (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [
        _makeLot(listingId: 'lot-1', variety: 'Arabica'),
      ]));
      await tester.pump();
      await tester.pump();

      expect(find.text('Arabica'), findsOneWidget);

      // The remove button is a GestureDetector with a favorite icon
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      // After removal, empty state should appear
      expect(find.text('No saved lots yet'), findsOneWidget);
    });

    // ── Direct Pay navigation ─────────────────────────────────────────────────

    testWidgets('tapping Direct Pay pushes a new route', (tester) async {
      await tester.pumpWidget(_wrap(initialLots: [_makeLot()]));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Direct Pay'));
      await tester.pumpAndSettle();

      // A new route has been pushed — the Saved Lots title is no longer on screen
      // (the payment screen replaces it in the navigator stack).
      expect(find.text('Saved Lots'), findsNothing);
    });
  });
}
