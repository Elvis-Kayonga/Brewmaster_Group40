part of 'listing_bloc.dart';

abstract class ListingEvent extends Equatable {
  const ListingEvent();
  @override
  List<Object?> get props => [];
}

class ActiveListingsLoadRequested extends ListingEvent {
  const ActiveListingsLoadRequested();
}

class FarmerListingsLoadRequested extends ListingEvent {
  final String farmerId;
  const FarmerListingsLoadRequested(this.farmerId);
  @override
  List<Object?> get props => [farmerId];
}

class ListingLoadRequested extends ListingEvent {
  final String listingId;
  const ListingLoadRequested(this.listingId);
  @override
  List<Object?> get props => [listingId];
}

class ListingCreateRequested extends ListingEvent {
  final CoffeeListing listing;
  final List<File>? images;
  const ListingCreateRequested({required this.listing, this.images});
  @override
  List<Object?> get props => [listing, images];
}

class ListingUpdateRequested extends ListingEvent {
  final CoffeeListing listing;
  final List<File>? newImages;
  const ListingUpdateRequested({required this.listing, this.newImages});
  @override
  List<Object?> get props => [listing, newImages];
}

class ListingDeleteRequested extends ListingEvent {
  final String listingId;
  const ListingDeleteRequested(this.listingId);
  @override
  List<Object?> get props => [listingId];
}

class ListingsSearchRequested extends ListingEvent {
  final SearchFilters filters;
  const ListingsSearchRequested(this.filters);
  @override
  List<Object?> get props => [filters];
}

// Internal stream events
class _ActiveListingsUpdated extends ListingEvent {
  final List<CoffeeListing> listings;
  const _ActiveListingsUpdated(this.listings);
  @override
  List<Object?> get props => [listings];
}

class _FarmerListingsUpdated extends ListingEvent {
  final List<CoffeeListing> listings;
  const _FarmerListingsUpdated(this.listings);
  @override
  List<Object?> get props => [listings];
}
