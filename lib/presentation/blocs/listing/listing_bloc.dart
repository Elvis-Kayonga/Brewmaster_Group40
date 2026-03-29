// Feature: brewmaster-marketplace
// BLoC for listing management: CRUD, image upload, search, real-time streams.
//
// Requirements: 2.1, 2.2, 2.5, 2.7, 4.1, 4.2, 16.1, 16.3 (BLoC state management)
// Developer: Developer 2

import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/models/search_filters.dart';
import '../../../domain/repositories/listing_repository.dart';

part 'listing_event.dart';
part 'listing_state.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  final ListingRepository _repository;

  StreamSubscription<List<CoffeeListing>>? _activeListingsSub;
  StreamSubscription<List<CoffeeListing>>? _farmerListingsSub;

  ListingBloc({required ListingRepository repository})
      : _repository = repository,
        super(const ListingInitial()) {
    on<ActiveListingsLoadRequested>(_onActiveListingsLoad);
    on<FarmerListingsLoadRequested>(_onFarmerListingsLoad);
    on<ListingCreateRequested>(_onListingCreate);
    on<ListingUpdateRequested>(_onListingUpdate);
    on<ListingDeleteRequested>(_onListingDelete);
    on<ListingsSearchRequested>(_onListingsSearch);
    on<_ActiveListingsUpdated>(_onActiveListingsUpdated);
    on<_FarmerListingsUpdated>(_onFarmerListingsUpdated);
  }

  Future<void> _onActiveListingsLoad(
    ActiveListingsLoadRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    await _activeListingsSub?.cancel();
    _activeListingsSub =
        _repository.watchActiveListings().listen((listings) {
      add(_ActiveListingsUpdated(listings));
    }, onError: (e) => add(_ActiveListingsUpdated(const [])));
  }

  Future<void> _onFarmerListingsLoad(
    FarmerListingsLoadRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    await _farmerListingsSub?.cancel();
    _farmerListingsSub =
        _repository.watchFarmerListings(event.farmerId).listen((listings) {
      add(_FarmerListingsUpdated(listings));
    }, onError: (e) => add(_FarmerListingsUpdated(const [])));
  }

  Future<void> _onListingCreate(
    ListingCreateRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    try {
      await _repository.createListing(event.listing, images: event.images);
      emit(const ListingActionSuccess('Listing created successfully'));
    } catch (e) {
      emit(ListingFailure(e.toString()));
    }
  }

  Future<void> _onListingUpdate(
    ListingUpdateRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    try {
      await _repository.updateListing(event.listing,
          newImages: event.newImages);
      emit(const ListingActionSuccess('Listing updated successfully'));
    } catch (e) {
      emit(ListingFailure(e.toString()));
    }
  }

  Future<void> _onListingDelete(
    ListingDeleteRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    try {
      await _repository.deleteListing(event.listingId);
      emit(const ListingActionSuccess('Listing deleted successfully'));
    } catch (e) {
      emit(ListingFailure(e.toString()));
    }
  }

  Future<void> _onListingsSearch(
    ListingsSearchRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());
    try {
      final results = await _repository.searchListings(event.filters);
      emit(ActiveListingsLoaded(results));
    } catch (e) {
      emit(ListingFailure(e.toString()));
    }
  }

  void _onActiveListingsUpdated(
    _ActiveListingsUpdated event,
    Emitter<ListingState> emit,
  ) {
    emit(ActiveListingsLoaded(event.listings));
  }

  void _onFarmerListingsUpdated(
    _FarmerListingsUpdated event,
    Emitter<ListingState> emit,
  ) {
    emit(FarmerListingsLoaded(event.listings));
  }

  @override
  Future<void> close() async {
    await _activeListingsSub?.cancel();
    await _farmerListingsSub?.cancel();
    return super.close();
  }
}
