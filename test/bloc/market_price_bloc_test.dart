// test/bloc/market_price_bloc_test.dart
//
// Unit tests for MarketPriceBloc — load via stream, sync, failure paths.
// Requirements: 3.1, 3.2, 3.4, 3.5

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/market_price.dart';
import 'package:brewmaster/domain/repositories/market_price_repository.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

MarketPrice _fakePrice({String id = 'price-1'}) => MarketPrice(
      id: id,
      variety: 'Arabica',
      grade: QualityGrade.specialty,
      lowPrice: 4.0,
      avgPrice: 5.0,
      highPrice: 6.0,
      currency: 'USD',
      updatedAt: _now,
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeMarketPriceRepository implements MarketPriceRepository {
  final StreamController<List<MarketPrice>> _priceController =
      StreamController<List<MarketPrice>>.broadcast();

  List<MarketPrice> _syncPrices = [_fakePrice()];
  Exception? _error;

  void setError(Exception e) => _error = e;
  void setSyncPrices(List<MarketPrice> prices) => _syncPrices = prices;
  void pushPrices(List<MarketPrice> prices) => _priceController.add(prices);
  void pushError(Object error) => _priceController.addError(error);

  @override
  Stream<List<MarketPrice>> watchMarketPrices() => _priceController.stream;

  @override
  Future<List<MarketPrice>> syncDailyPrices() async {
    if (_error != null) throw _error!;
    return _syncPrices;
  }

  @override
  Future<List<MarketPrice>> getMarketPrices() async {
    if (_error != null) throw _error!;
    return _syncPrices;
  }

  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async {
    if (_error != null) throw _error!;
    return _syncPrices
        .where((p) => p.variety == variety)
        .where((p) => grade == null || p.grade == grade)
        .toList();
  }

  @override
  DateTime? get lastSyncTime => null;

  void dispose() => _priceController.close();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('MarketPriceBloc — initial state', () {
    test('starts in MarketPriceInitial', () {
      final repo = _FakeMarketPriceRepository();
      final bloc = MarketPriceBloc(repository: repo);
      expect(bloc.state, isA<MarketPriceInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('MarketPriceBloc — MarketPricesLoadRequested', () {
    test('emits MarketPriceLoading then MarketPricesLoaded via stream',
        () async {
      final repo = _FakeMarketPriceRepository();
      final bloc = MarketPriceBloc(repository: repo);
      final states = <MarketPriceState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MarketPricesLoadRequested());
      await Future<void>.delayed(Duration.zero);

      final price = _fakePrice();
      repo.pushPrices([price]);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is MarketPriceLoading), isTrue);
      expect(states.last, isA<MarketPricesLoaded>());
      expect((states.last as MarketPricesLoaded).prices, contains(price));

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits MarketPricesLoaded with empty list', () async {
      final repo = _FakeMarketPriceRepository();
      final bloc = MarketPriceBloc(repository: repo);
      final states = <MarketPriceState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MarketPricesLoadRequested());
      await Future<void>.delayed(Duration.zero);

      repo.pushPrices([]);
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<MarketPricesLoaded>());
      expect((states.last as MarketPricesLoaded).prices, isEmpty);

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits MarketPriceFailure when stream emits an error', () async {
      final repo = _FakeMarketPriceRepository();
      final bloc = MarketPriceBloc(repository: repo);
      final states = <MarketPriceState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MarketPricesLoadRequested());
      await Future<void>.delayed(Duration.zero);

      repo.pushError(Exception('stream error'));
      await Future<void>.delayed(Duration.zero);

      expect(states.last, isA<MarketPriceFailure>());
      expect(
        (states.last as MarketPriceFailure).message,
        'Failed to load prices',
      );

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('stream can emit multiple updates', () async {
      final repo = _FakeMarketPriceRepository();
      final bloc = MarketPriceBloc(repository: repo);
      final states = <MarketPriceState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MarketPricesLoadRequested());
      await Future<void>.delayed(Duration.zero);

      repo.pushPrices([_fakePrice(id: 'price-1')]);
      await Future<void>.delayed(Duration.zero);

      repo.pushPrices([_fakePrice(id: 'price-1'), _fakePrice(id: 'price-2')]);
      await Future<void>.delayed(Duration.zero);

      final loadedStates =
          states.whereType<MarketPricesLoaded>().toList();
      expect(loadedStates.length, 2);
      expect(loadedStates.last.prices.length, 2);

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });
  });

  group('MarketPriceBloc — MarketPricesSyncRequested', () {
    test('emits MarketPriceLoading then MarketPricesLoaded on success',
        () async {
      final repo = _FakeMarketPriceRepository();
      final price = _fakePrice();
      repo.setSyncPrices([price]);
      final bloc = MarketPriceBloc(repository: repo);
      final states = <MarketPriceState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const MarketPricesSyncRequested());
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is MarketPriceLoading), isTrue);
      expect(states.last, isA<MarketPricesLoaded>());
      expect((states.last as MarketPricesLoaded).prices, contains(price));

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits MarketPriceFailure on sync exception', () async {
      final repo = _FakeMarketPriceRepository();
      repo.setError(Exception('sync failed'));
      final bloc = MarketPriceBloc(repository: repo);

      bloc.add(const MarketPricesSyncRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MarketPriceFailure>());

      bloc.close();
      repo.dispose();
    });

    test('sync with empty result emits empty MarketPricesLoaded', () async {
      final repo = _FakeMarketPriceRepository();
      repo.setSyncPrices([]);
      final bloc = MarketPriceBloc(repository: repo);

      bloc.add(const MarketPricesSyncRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<MarketPricesLoaded>());
      expect((bloc.state as MarketPricesLoaded).prices, isEmpty);

      bloc.close();
      repo.dispose();
    });
  });

  group('MarketPriceState — equality', () {
    test('MarketPriceInitial instances are equal', () {
      expect(const MarketPriceInitial(), equals(const MarketPriceInitial()));
    });

    test('MarketPriceLoading instances are equal', () {
      expect(const MarketPriceLoading(), equals(const MarketPriceLoading()));
    });

    test('MarketPriceFailure equality based on message', () {
      expect(
        const MarketPriceFailure('err'),
        equals(const MarketPriceFailure('err')),
      );
    });
  });
}
