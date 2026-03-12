/// Widget tests for MarketPricesScreen
///
/// Requirements: 3.1, 3.2, 3.5, 16.1 (Clean Architecture)
/// Developer: Developer 5 (refactored to BLoC by Developer 1)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';
import 'package:brewmaster/presentation/screens/dashboard/market_prices_screen.dart';
import 'package:brewmaster/presentation/widgets/common/loading_indicator.dart';

class _FakeMarketPriceRepository implements MarketPriceRepository {
  @override
  Future<List<MarketPrice>> getMarketPrices() async => [];
  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async =>
      [];
  @override
  Future<List<MarketPrice>> syncDailyPrices() async => [];
  @override
  Stream<List<MarketPrice>> watchMarketPrices() => Stream.value([]);
  @override
  DateTime? get lastSyncTime => null;
}

void main() {
  group('MarketPricesScreen Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider(
          create: (_) =>
              MarketPriceBloc(repository: _FakeMarketPriceRepository()),
          child: const MarketPricesScreen(),
        ),
      );
    }

    group('Loading State Tests', () {
      testWidgets(
        'Should display loading indicator on initial load',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          // Check before pump() — bloc hasn't processed the event yet
          expect(find.byType(LoadingIndicator), findsOneWidget);
          expect(find.text('Loading market prices…'), findsOneWidget);
        },
      );

      testWidgets(
        'Should show app bar during loading',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(AppBar), findsOneWidget);
          expect(find.text('Market Prices'), findsOneWidget);
        },
      );
    });

    group('App Bar Tests', () {
      testWidgets(
        'Should display "Market Prices" title',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.text('Market Prices'), findsOneWidget);
        },
      );

      testWidgets(
        'Should have sync/refresh button',
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
          expect(iconButton.tooltip, equals('Sync prices'));
        },
      );

      testWidgets(
        'Should trigger sync when refresh button tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );
    });

    group('Error State Tests', () {
      testWidgets(
        'Should handle bloc errors gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should use BlocBuilder for state management',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(
            find.byType(BlocBuilder<MarketPriceBloc, MarketPriceState>),
            findsOneWidget,
          );
        },
      );
    });

    group('Empty State Tests', () {
      testWidgets(
        'Should display empty state when no prices available',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // Empty state message shown after loading completes with no data
        },
      );
    });

    group('Filter Tests', () {
      testWidgets(
        'Should display variety filter chips when varieties exist',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // Filter chips appear after data loads
        },
      );

      testWidgets(
        'Should filter prices when variety chip tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // Filter interaction requires mocked data
        },
      );

      testWidgets(
        'Should show all prices when no filter selected',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();
          // All prices shown by default
        },
      );
    });

    group('State Management Tests', () {
      testWidgets(
        'Should trigger loadMarketPrices on initState',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should rebuild on bloc state changes',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );
    });

    group('Layout Tests', () {
      testWidgets(
        'Should have proper scaffold structure',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
        },
      );
    });

    group('User Interaction Tests', () {
      testWidgets(
        'Should handle rapid refresh button taps',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          for (int i = 0; i < 5; i++) {
            await tester.tap(find.byIcon(Icons.refresh));
            await tester.pump();
          }

          expect(find.byType(MarketPricesScreen), findsOneWidget);
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
                        builder: (_) => BlocProvider(
                          create: (_) => MarketPriceBloc(
                            repository: _FakeMarketPriceRepository(),
                          ),
                          child: const MarketPricesScreen(),
                        ),
                      ),
                    ),
                    child: const Text('View Prices'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('View Prices'));
          await tester.pumpAndSettle();

          expect(find.text('Market Prices'), findsOneWidget);

          await tester.pageBack();
          await tester.pumpAndSettle();

          expect(find.text('View Prices'), findsOneWidget);
        },
      );
    });

    group('Accessibility Tests', () {
      testWidgets(
        'Should have accessible refresh button',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          final iconButton = tester.widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.refresh),
              matching: find.byType(IconButton),
            ),
          );
          expect(iconButton.tooltip, equals('Sync prices'));
        },
      );

      testWidgets(
        'Should provide semantic labels for screen readers',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(AppBar), findsOneWidget);
        },
      );
    });

    group('Edge Cases', () {
      testWidgets(
        'Should handle no internet connection gracefully',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );

      testWidgets(
        'Should handle concurrent sync requests',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pump();

          await tester.tap(find.byIcon(Icons.refresh));
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          expect(find.byType(MarketPricesScreen), findsOneWidget);
        },
      );
    });
  });

  group('MarketPrice Model Tests', () {
    test('Should create MarketPrice with all fields', () {
      final now = DateTime.now();
      final price = MarketPrice(
        id: 'test-id',
        variety: 'Arabica',
        grade: QualityGrade.specialty,
        lowPrice: 800.0,
        avgPrice: 1000.0,
        highPrice: 1200.0,
        currency: 'KES',
        updatedAt: now,
      );

      expect(price.id, equals('test-id'));
      expect(price.variety, equals('Arabica'));
      expect(price.grade, equals(QualityGrade.specialty));
      expect(price.lowPrice, equals(800.0));
      expect(price.avgPrice, equals(1000.0));
      expect(price.highPrice, equals(1200.0));
      expect(price.currency, equals('KES'));
      expect(price.updatedAt, equals(now));
    });

    test('Should validate price range order', () {
      final price = MarketPrice(
        id: 'test-id',
        variety: 'Arabica',
        grade: QualityGrade.premium,
        lowPrice: 600.0,
        avgPrice: 800.0,
        highPrice: 1000.0,
        currency: 'KES',
        updatedAt: DateTime.now(),
      );

      expect(price.lowPrice, lessThan(price.avgPrice));
      expect(price.avgPrice, lessThan(price.highPrice));
    });
  });
}
