import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/repositories/listing_repository.dart';

part 'listing_detail_event.dart';
part 'listing_detail_state.dart';

class ListingDetailBloc
    extends Bloc<ListingDetailEvent, ListingDetailState> {
  final ListingRepository _repository;

  ListingDetailBloc({required ListingRepository repository})
      : _repository = repository,
        super(const ListingDetailInitial()) {
    on<ListingDetailLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    ListingDetailLoadRequested event,
    Emitter<ListingDetailState> emit,
  ) async {
    emit(const ListingDetailLoading());
    try {
      final listing = await _repository.getListing(event.listingId);
      if (listing == null) {
        emit(const ListingDetailFailure('Listing not found'));
      } else {
        emit(ListingDetailLoaded(listing));
      }
    } catch (e) {
      emit(ListingDetailFailure(e.toString()));
    }
  }
}
