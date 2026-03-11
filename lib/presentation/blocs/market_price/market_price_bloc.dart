import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/market_price.dart';
import '../../../domain/repositories/market_price_repository.dart';

part 'market_price_event.dart';
part 'market_price_state.dart';

/// BLoC for market price data.
///
/// Events: [MarketPricesLoadRequested], [MarketPricesSyncRequested]
/// Requirements: 3.1, 3.2, 3.4, 3.5
/// Developer: Developer 5
class MarketPriceBloc extends Bloc<MarketPriceEvent, MarketPriceState> {
  final MarketPriceRepository _repository;

  MarketPriceBloc({required MarketPriceRepository repository})
      : _repository = repository,
        super(const MarketPriceInitial()) {
    on<MarketPricesLoadRequested>(_onLoad);
    on<MarketPricesSyncRequested>(_onSync);
  }

  Future<void> _onLoad(
    MarketPricesLoadRequested event,
    Emitter<MarketPriceState> emit,
  ) async {
    emit(const MarketPriceLoading());
    try {
      final prices = await _repository.getMarketPrices();
      emit(MarketPricesLoaded(prices));
    } catch (e) {
      emit(MarketPriceFailure(e.toString()));
    }
  }

  Future<void> _onSync(
    MarketPricesSyncRequested event,
    Emitter<MarketPriceState> emit,
  ) async {
    emit(const MarketPriceLoading());
    try {
      final prices = await _repository.syncDailyPrices();
      emit(MarketPricesLoaded(prices));
    } catch (e) {
      emit(MarketPriceFailure(e.toString()));
    }
  }
}
