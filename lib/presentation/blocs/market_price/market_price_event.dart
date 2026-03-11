part of 'market_price_bloc.dart';

abstract class MarketPriceEvent extends Equatable {
  const MarketPriceEvent();

  @override
  List<Object?> get props => [];
}

/// Load all market prices (uses offline cache when unavailable).
class MarketPricesLoadRequested extends MarketPriceEvent {
  const MarketPricesLoadRequested();
}

/// Force a fresh sync from the server (Requirement 3.4).
class MarketPricesSyncRequested extends MarketPriceEvent {
  const MarketPricesSyncRequested();
}
