part of 'listing_detail_bloc.dart';

abstract class ListingDetailState extends Equatable {
  const ListingDetailState();
  @override
  List<Object?> get props => [];
}

class ListingDetailInitial extends ListingDetailState {
  const ListingDetailInitial();
}

class ListingDetailLoading extends ListingDetailState {
  const ListingDetailLoading();
}

class ListingDetailLoaded extends ListingDetailState {
  final CoffeeListing listing;
  const ListingDetailLoaded(this.listing);
  @override
  List<Object?> get props => [listing];
}

class ListingDetailFailure extends ListingDetailState {
  final String message;
  const ListingDetailFailure(this.message);
  @override
  List<Object?> get props => [message];
}
