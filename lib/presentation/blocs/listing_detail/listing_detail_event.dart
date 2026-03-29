part of 'listing_detail_bloc.dart';

abstract class ListingDetailEvent extends Equatable {
  const ListingDetailEvent();
  @override
  List<Object?> get props => [];
}

class ListingDetailLoadRequested extends ListingDetailEvent {
  final String listingId;
  const ListingDetailLoadRequested(this.listingId);
  @override
  List<Object?> get props => [listingId];
}
