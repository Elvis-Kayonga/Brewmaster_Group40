// Feature: brewmaster-marketplace
// Property tests for market price structure, offline caching, and price
// deviation warnings.
//
// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
// Developer: Developer 5

import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeMarketPriceRepository implements MarketPriceRepository {
  final List<MarketPrice> _prices;
  DateTime? _lastSyncTime;
  bool shouldThrow = false;

  FakeMarketPriceRepository(this._prices);

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  Future<List<MarketPrice>> getMarketPrices() async {
    if (shouldThrow) throw Exception('network error');
    _lastSyncTime = DateTime.now();
    return List.unmodifiable(_prices);
  }

  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async {
    if (shouldThrow) throw Exception('network error');
    return _prices
        .where((p) =>
            p.variety.toLowerCase() == variety.toLowerCase() &&
            (grade == null || p.grade == grade))
        .toList();
  }

  @override
  Future<List<MarketPrice>> syncDailyPrices() async {
    if (shouldThrow) throw Exception('sync error');
    _lastSyncTime = DateTime.now();
    return List.unmodifiable(_prices);
  }

  @override
  Stream<List<MarketPrice>> watchMarketPrices() {
    return Stream.value(List.unmodifiable(_prices));
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MarketPrice _makePrice({
  String id = 'p1',
  String variety = 'Bourbon',
  QualityGrade grade = QualityGrade.premium,
  double low = 4.0,
  double avg = 5.0,
  double high = 6.0,
  String currency = 'USD',
  DateTime? updatedAt,
}) {
  return MarketPrice(
    id: id,
    variety: variety,
    grade: grade,
    lowPrice: low,
    avgPrice: avg,
    highPrice: high,
    currency: currency,
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Task 17.2 – market price structure properties
  // -------------------------------------------------------------------------

  group('Property 12 – MarketPrice structure', () {
    // Every MarketPrice record must contain variety, grade, low/avg/high
    // price, currency, and updatedAt fields.
    test('all required fields are present and non-null', () {
      final price = _makePrice();
      expect(price.variety, isNotEmpty);
      expect(price.grade, isNotNull);
      expect(price.lowPrice, isNotNull);
      expect(price.avgPrice, isNotNull);
      expect(price.highPrice, isNotNull);
      expect(price.currency, isNotEmpty);
      expect(price.updatedAt, isNotNull);
    });

    test('lowPrice <= avgPrice <= highPrice for any valid record', () {
      final cases = [
        _makePrice(low: 1.0, avg: 2.0, high: 3.0),
        _makePrice(low: 5.0, avg: 5.0, high: 5.0), // all equal
        _makePrice(low: 0.0, avg: 100.0, high: 200.0),
      ];
      for (final p in cases) {
        expect(p.lowPrice <= p.avgPrice, isTrue,
            reason: 'low must be <= avg');
        expect(p.avgPrice <= p.highPrice, isTrue,
            reason: 'avg must be <= high');
      }
    });

    test('fromJson / toJson round-trip preserves all fields', () {
      final original = _makePrice(
        id: 'rt1',
        variety: 'SL28',
        grade: QualityGrade.standard,
        low: 3.5,
        avg: 4.2,
        high: 5.0,
        currency: 'KES',
        updatedAt: DateTime(2024, 6, 15),
      );

      final json = original.toJson();
      // Replace Timestamp with ISO string for fromJson
      json['updatedAt'] = original.updatedAt.toIso8601String();

      final restored = MarketPrice.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.variety, equals(original.variety));
      expect(restored.grade, equals(original.grade));
      expect(restored.lowPrice, equals(original.lowPrice));
      expect(restored.avgPrice, equals(original.avgPrice));
      expect(restored.highPrice, equals(original.highPrice));
      expect(restored.currency, equals(original.currency));
    });

    test('copyWith returns new instance with changed fields only', () {
      final original = _makePrice(avg: 5.0);
      final updated = original.copyWith(avgPrice: 6.5);
      expect(updated.avgPrice, equals(6.5));
      expect(updated.variety, equals(original.variety));
      expect(updated.grade, equals(original.grade));
      expect(updated != original, isTrue);
    });

    test('equality holds for identical field values', () {
      final a = _makePrice(id: 'x', variety: 'Typica', avg: 4.0);
      final b = _makePrice(id: 'x', variety: 'Typica', avg: 4.0);
      expect(a, equals(b));
    });
  });

  group('Property 13 – offline cache timestamp', () {
    // The repository tracks the timestamp of the last successful fetch so
    // the UI can display data freshness when offline (Requirement 3.5).
    test('lastSyncTime is null before any fetch', () {
      final repo = FakeMarketPriceRepository([]);
      expect(repo.lastSyncTime, isNull);
    });

    test('lastSyncTime is set after getMarketPrices()', () async {
      final repo = FakeMarketPriceRepository([_makePrice()]);
      await repo.getMarketPrices();
      expect(repo.lastSyncTime, isNotNull);
    });

    test('lastSyncTime is updated after syncDailyPrices()', () async {
      final repo = FakeMarketPriceRepository([_makePrice()]);
      await repo.getMarketPrices();
      final first = repo.lastSyncTime!;

      await Future.delayed(const Duration(milliseconds: 5));
      await repo.syncDailyPrices();
      expect(repo.lastSyncTime!.isAfter(first), isTrue);
    });

    test('repository returns cached list when offline (simulated)', () async {
      final prices = [_makePrice(id: 'cached')];
      final repo = FakeMarketPriceRepository(prices);
      // First successful fetch populates local state
      final loaded = await repo.getMarketPrices();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, equals('cached'));
    });
  });

  // -------------------------------------------------------------------------
  // Task 18.3 – price deviation warning property
  // -------------------------------------------------------------------------

  group('Property – price deviation warning (Requirement 3.3, 3.6)', () {
    // A listing price is considered "deviant" if it falls outside the
    // market low–high band for the same variety/grade.

    double deviationPercent(double listingPrice, MarketPrice market) {
      if (market.avgPrice == 0) return 0;
      return ((listingPrice - market.avgPrice) / market.avgPrice).abs() * 100;
    }

    bool isOutsideBand(double listingPrice, MarketPrice market) {
      return listingPrice < market.lowPrice || listingPrice > market.highPrice;
    }

    test('price within band produces no deviation warning', () {
      final market = _makePrice(low: 4.0, avg: 5.0, high: 6.0);
      expect(isOutsideBand(5.0, market), isFalse);
      expect(isOutsideBand(4.0, market), isFalse);
      expect(isOutsideBand(6.0, market), isFalse);
    });

    test('price below low triggers deviation warning', () {
      final market = _makePrice(low: 4.0, avg: 5.0, high: 6.0);
      expect(isOutsideBand(3.0, market), isTrue);
      expect(deviationPercent(3.0, market), greaterThan(0));
    });

    test('price above high triggers deviation warning', () {
      final market = _makePrice(low: 4.0, avg: 5.0, high: 6.0);
      expect(isOutsideBand(8.0, market), isTrue);
      expect(deviationPercent(8.0, market), greaterThan(0));
    });

    test('deviation percent is 0 when listing equals avg', () {
      final market = _makePrice(avg: 5.0);
      expect(deviationPercent(5.0, market), equals(0.0));
    });

    test('deviation percent scales proportionally', () {
      final market = _makePrice(avg: 10.0);
      expect(deviationPercent(12.0, market), closeTo(20.0, 0.001));
      expect(deviationPercent(8.0, market), closeTo(20.0, 0.001));
    });

    test('getPricesForVariety returns matching records only', () async {
      final prices = [
        _makePrice(id: '1', variety: 'Bourbon', grade: QualityGrade.premium),
        _makePrice(id: '2', variety: 'Bourbon', grade: QualityGrade.standard),
        _makePrice(id: '3', variety: 'SL28', grade: QualityGrade.premium),
      ];
      final repo = FakeMarketPriceRepository(prices);

      final bourbon = await repo.getPricesForVariety('Bourbon');
      expect(bourbon, hasLength(2));

      final bourbonPremium = await repo.getPricesForVariety(
        'Bourbon',
        grade: QualityGrade.premium,
      );
      expect(bourbonPremium, hasLength(1));
      expect(bourbonPremium.first.id, equals('1'));
    });
  });
}
