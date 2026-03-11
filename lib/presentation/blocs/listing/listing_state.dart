part of 'listing_bloc.dart';

abstract class ListingState extends Equatable {
  const ListingState();
  @override
  List<Object?> get props => [];
}

class ListingInitial extends ListingState {
  const ListingInitial();
}

class ListingLoading extends ListingState {
  const ListingLoading();
}

class ActiveListingsLoaded extends ListingState {
  final List<CoffeeListing> listings;
  const ActiveListingsLoaded(this.listings);
  @override
  List<Object?> get props => [listings];
}

class FarmerListingsLoaded extends ListingState {
  final List<CoffeeListing> listings;
  const FarmerListingsLoaded(this.listings);
  @override
  List<Object?> get props => [listings];
}

class ListingDetailLoaded extends ListingState {
  final CoffeeListing listing;
  const ListingDetailLoaded(this.listing);
  @override
  List<Object?> get props => [listing];
}

class ListingActionSuccess extends ListingState {
  final String message;
  const ListingActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class ListingFailure extends ListingState {
  final String message;
  const ListingFailure(this.message);
  @override
  List<Object?> get props => [message];
}
