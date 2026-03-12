part of 'market_price_bloc.dart';

abstract class MarketPriceState extends Equatable {
  const MarketPriceState();

  @override
  List<Object?> get props => [];
}

class MarketPriceInitial extends MarketPriceState {
  const MarketPriceInitial();
}

class MarketPriceLoading extends MarketPriceState {
  const MarketPriceLoading();
}

class MarketPricesLoaded extends MarketPriceState {
  final List<MarketPrice> prices;

  const MarketPricesLoaded(this.prices);

  @override
  List<Object?> get props => [prices];
}

class MarketPriceFailure extends MarketPriceState {
  final String message;

  const MarketPriceFailure(this.message);

  @override
  List<Object?> get props => [message];
}
