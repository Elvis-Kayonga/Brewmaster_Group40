// test/bloc/listing_bloc_test.dart
//
// Unit tests for ListingBloc — covers load, CRUD, search, and stream events.
// Requirements: 2.1, 2.2, 2.5, 2.7, 4.1, 4.2

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

CoffeeListing _fakeListing({String id = 'listing-1'}) => CoffeeListing(
      listingId: id,
      farmerId: 'farmer-1',
      variety: 'Arabica',
      quantity: 100,
      pricePerKg: 5.0,
      processingMethod: ProcessingMethod.washed,
      altitude: 1800,
      harvestDate: _now,
      qualityScore: 85,
      description: 'Test listing',
      images: const [],
      location: 'Kenya',
      status: ListingStatus.active,
      createdAt: _now,
      updatedAt: _now,
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeListingRepository implements ListingRepository {
  final StreamController<List<CoffeeListing>> _activeController =
      StreamController<List<CoffeeListing>>.broadcast();
  final StreamController<List<CoffeeListing>> _farmerController =
      StreamController<List<CoffeeListing>>.broadcast();

  // Controls for test injection
  CoffeeListing? _listing;
  Exception? _error;
  List<CoffeeListing> _searchResults = [];

  void setListing(CoffeeListing? l) => _listing = l;
  void setError(Exception e) => _error = e;
  void setSearchResults(List<CoffeeListing> r) => _searchResults = r;
  void pushActive(List<CoffeeListing> listings) =>
      _activeController.add(listings);
  void pushFarmer(List<CoffeeListing> listings) =>
      _farmerController.add(listings);

  @override
  Stream<List<CoffeeListing>> watchActiveListings() => _activeController.stream;

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      _farmerController.stream;

  @override
  Future<CoffeeListing?> getListing(String listingId) async {
    if (_error != null) throw _error!;
    return _listing;
  }

  @override
  Future<String> createListing(CoffeeListing listing,
      {List<File>? images}) async {
    if (_error != null) throw _error!;
    return listing.listingId;
  }

  @override
  Future<void> updateListing(CoffeeListing listing,
      {List<File>? newImages}) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<void> deleteListing(String listingId) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    if (_error != null) throw _error!;
    return _searchResults;
  }

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage(
          {int pageSize = 20, Object? startAfter}) async =>
      PaginatedResult(items: [], cursor: null, hasMore: false);

  void dispose() {
    _activeController.close();
    _farmerController.close();
  }
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ListingBloc — initial state', () {
    test('starts in ListingInitial', () {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);
      expect(bloc.state, isA<ListingInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — ActiveListingsLoadRequested', () {
    test('emits ListingLoading then ActiveListingsLoaded via stream', () async {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);

      final states = <ListingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const ActiveListingsLoadRequested());
      await Future<void>.delayed(Duration.zero);

      final listing = _fakeListing();
      repo.pushActive([listing]);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is ListingLoading), isTrue);
      expect(states.last, isA<ActiveListingsLoaded>());
      expect((states.last as ActiveListingsLoaded).listings, [listing]);

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — FarmerListingsLoadRequested', () {
    test('emits ListingLoading then FarmerListingsLoaded via stream', () async {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);

      final states = <ListingState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const FarmerListingsLoadRequested('farmer-1'));
      await Future<void>.delayed(Duration.zero);

      final listing = _fakeListing();
      repo.pushFarmer([listing]);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is ListingLoading), isTrue);
      expect(states.last, isA<FarmerListingsLoaded>());

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — ListingCreateRequested', () {
    test('emits ListingActionSuccess on success', () async {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);

      bloc.add(ListingCreateRequested(listing: _fakeListing()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingActionSuccess>());
      expect(
        (bloc.state as ListingActionSuccess).message,
        'Listing created successfully',
      );

      bloc.close();
      repo.dispose();
    });

    test('emits ListingFailure on exception', () async {
      final repo = _FakeListingRepository();
      repo.setError(Exception('upload failed'));
      final bloc = ListingBloc(repository: repo);

      bloc.add(ListingCreateRequested(listing: _fakeListing()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — ListingUpdateRequested', () {
    test('emits ListingActionSuccess on success', () async {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);

      bloc.add(ListingUpdateRequested(listing: _fakeListing()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingActionSuccess>());
      expect(
        (bloc.state as ListingActionSuccess).message,
        'Listing updated successfully',
      );

      bloc.close();
      repo.dispose();
    });

    test('emits ListingFailure on exception', () async {
      final repo = _FakeListingRepository();
      repo.setError(Exception('update failed'));
      final bloc = ListingBloc(repository: repo);

      bloc.add(ListingUpdateRequested(listing: _fakeListing()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — ListingDeleteRequested', () {
    test('emits ListingActionSuccess on success', () async {
      final repo = _FakeListingRepository();
      final bloc = ListingBloc(repository: repo);

      bloc.add(const ListingDeleteRequested( 'listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingActionSuccess>());
      expect(
        (bloc.state as ListingActionSuccess).message,
        'Listing deleted successfully',
      );

      bloc.close();
      repo.dispose();
    });

    test('emits ListingFailure on exception', () async {
      final repo = _FakeListingRepository();
      repo.setError(Exception('delete failed'));
      final bloc = ListingBloc(repository: repo);

      bloc.add(const ListingDeleteRequested( 'listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingFailure>());

      bloc.close();
      repo.dispose();
    });
  });

  group('ListingBloc — ListingsSearchRequested', () {
    test('emits ActiveListingsLoaded with search results', () async {
      final repo = _FakeListingRepository();
      final listing = _fakeListing();
      repo.setSearchResults([listing]);
      final bloc = ListingBloc(repository: repo);

      bloc.add(
          const ListingsSearchRequested( SearchFilters(query: 'arabica')));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ActiveListingsLoaded>());
      expect((bloc.state as ActiveListingsLoaded).listings, [listing]);

      bloc.close();
      repo.dispose();
    });

    test('emits ActiveListingsLoaded with empty results', () async {
      final repo = _FakeListingRepository();
      repo.setSearchResults([]);
      final bloc = ListingBloc(repository: repo);

      bloc.add(const ListingsSearchRequested( SearchFilters()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ActiveListingsLoaded>());
      expect((bloc.state as ActiveListingsLoaded).listings, isEmpty);

      bloc.close();
      repo.dispose();
    });

    test('emits ListingFailure on exception', () async {
      final repo = _FakeListingRepository();
      repo.setError(Exception('search failed'));
      final bloc = ListingBloc(repository: repo);

      bloc.add(const ListingsSearchRequested( SearchFilters()));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingFailure>());

      bloc.close();
      repo.dispose();
    });
  });
}
