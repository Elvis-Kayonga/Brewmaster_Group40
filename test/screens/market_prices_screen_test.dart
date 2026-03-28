// Widget tests for MarketPricesScreen
// Coverage: loading, error, loaded (empty list, non-empty list), variety filter chips.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/dashboard/market_prices_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake repositories ─────────────────────────────────────────────────────────

class FakeMarketPriceRepository implements MarketPriceRepository {
  List<MarketPrice> prices;
  Exception? error;

  FakeMarketPriceRepository({this.prices = const []});

  @override
  Future<List<MarketPrice>> getMarketPrices() async {
    if (error != null) throw error!;
    return prices;
  }

  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async =>
      prices.where((p) => p.variety == variety).toList();

  @override
  Future<List<MarketPrice>> syncDailyPrices() async {
    if (error != null) throw error!;
    return prices;
  }

  @override
  Stream<List<MarketPrice>> watchMarketPrices() => Stream.value(prices);

  @override
  DateTime? get lastSyncTime => null;
}

/// syncDailyPrices never completes — keeps bloc in loading state.
class _NeverSyncingRepository implements MarketPriceRepository {
  @override
  Future<List<MarketPrice>> syncDailyPrices() =>
      Completer<List<MarketPrice>>().future; // never completes

  @override
  Future<List<MarketPrice>> getMarketPrices() async => [];

  @override
  Future<List<MarketPrice>> getPricesForVariety(String variety,
          {QualityGrade? grade}) async =>
      [];

  @override
  Stream<List<MarketPrice>> watchMarketPrices() => Stream.value([]);

  @override
  DateTime? get lastSyncTime => null;
}

// ── Fixture ───────────────────────────────────────────────────────────────────

MarketPrice _makePrice({
  String id = 'p1',
  String variety = 'Bourbon',
  QualityGrade grade = QualityGrade.specialty,
  double low = 5.0,
  double avg = 7.0,
  double high = 9.0,
  String currency = 'USD',
}) =>
    MarketPrice(
      id: id,
      variety: variety,
      grade: grade,
      lowPrice: low,
      avgPrice: avg,
      highPrice: high,
      currency: currency,
      updatedAt: DateTime(2024, 6, 1),
    );

// ── Helper ────────────────────────────────────────────────────────────────────

/// Builds the screen with all blocs created INSIDE create callbacks.
/// [neverSync]  — keeps bloc in loading state (syncDailyPrices never completes).
/// [syncError]  — syncDailyPrices throws, bloc emits MarketPriceFailure.
/// [prices]     — prices returned by syncDailyPrices (loaded state).
Widget _wrap({
  List<MarketPrice> prices = const [],
  bool neverSync = false,
  bool syncError = false,
  String errorMessage = 'Failed to sync prices',
}) {
  final repo = neverSync
      ? _NeverSyncingRepository() as MarketPriceRepository
      : (FakeMarketPriceRepository(prices: prices)
          ..error = syncError ? Exception(errorMessage) : null);

  final userRepo = FakeUserRepository();
  final authRepo = FakeAuthRepository();
  final notifRepo = FakeNotificationRepository();

  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<MarketPriceBloc>(
          create: (_) => MarketPriceBloc(repository: repo),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: authRepo,
            userRepository: userRepo,
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: userRepo),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: notifRepo),
        ),
      ],
      child: const MarketPricesScreen(),
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

  group('MarketPricesScreen', () {
    testWidgets('shows loading indicator when sync is pending', (tester) async {
      await tester.pumpWidget(_wrap(neverSync: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error widget when syncDailyPrices throws', (tester) async {
      await tester.pumpWidget(
          _wrap(syncError: true, errorMessage: 'Failed to sync prices'));
      await tester.pump();

      expect(find.textContaining('Failed to sync prices'), findsOneWidget);
    });

    testWidgets('shows "Market Prices" header when loaded', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.textContaining('Market'), findsWidgets);
      expect(find.textContaining('Prices'), findsWidgets);
    });

    testWidgets('shows LIVE COMMODITY INDEX subtitle', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('LIVE COMMODITY INDEX'), findsOneWidget);
    });

    testWidgets('shows "No market prices available." when list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('No market prices available.'), findsOneWidget);
    });

    testWidgets('shows price card with variety name when prices loaded',
        (tester) async {
      await tester.pumpWidget(_wrap(prices: [_makePrice(variety: 'Bourbon')]));
      await tester.pump();

      expect(find.text('Bourbon'), findsWidgets);
    });

    testWidgets('shows grade chip on price card', (tester) async {
      await tester
          .pumpWidget(_wrap(prices: [_makePrice(grade: QualityGrade.specialty)]));
      await tester.pump();

      expect(find.text('Specialty'), findsOneWidget);
    });

    testWidgets('shows premium grade chip on price card', (tester) async {
      await tester
          .pumpWidget(_wrap(prices: [_makePrice(grade: QualityGrade.premium)]));
      await tester.pump();

      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('shows standard grade chip on price card', (tester) async {
      await tester
          .pumpWidget(_wrap(prices: [_makePrice(grade: QualityGrade.standard)]));
      await tester.pump();

      expect(find.text('Standard'), findsOneWidget);
    });

    testWidgets('shows Low, Average, High price labels', (tester) async {
      await tester.pumpWidget(_wrap(prices: [_makePrice()]));
      await tester.pump();

      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Average'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('shows updated date on price card', (tester) async {
      await tester.pumpWidget(_wrap(prices: [_makePrice()]));
      await tester.pump();

      // Date format: 'd MMM yyyy' → "1 Jun 2024"
      expect(find.textContaining('1 Jun 2024'), findsOneWidget);
    });

    testWidgets('shows variety filter chip when multiple varieties present',
        (tester) async {
      final prices = [
        _makePrice(id: 'p1', variety: 'Bourbon'),
        _makePrice(id: 'p2', variety: 'Typica'),
      ];
      await tester.pumpWidget(_wrap(prices: prices));
      await tester.pump();

      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('shows refresh icon button in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows "Brew Master" app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows multiple price cards for multiple prices', (tester) async {
      final prices = [
        _makePrice(id: 'p1', variety: 'Bourbon', grade: QualityGrade.specialty),
        _makePrice(id: 'p2', variety: 'Typica', grade: QualityGrade.premium),
      ];
      await tester.pumpWidget(_wrap(prices: prices));
      await tester.pump();

      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows currency and price values on card', (tester) async {
      await tester.pumpWidget(_wrap(prices: [_makePrice(avg: 7.50, currency: 'USD')]));
      await tester.pump();

      expect(find.textContaining('7.50'), findsWidgets);
    });
  });
}
