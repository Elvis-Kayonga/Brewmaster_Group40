// test/bloc/listing_detail_bloc_test.dart
//
// Unit tests for ListingDetailBloc — covers load, not-found, and error cases.

import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/presentation/blocs/listing_detail/listing_detail_bloc.dart';

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
  CoffeeListing? _listing;
  Exception? _error;

  void setListing(CoffeeListing? l) => _listing = l;
  void setError(Exception e) => _error = e;

  @override
  Stream<List<CoffeeListing>> watchActiveListings() => const Stream.empty();

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      const Stream.empty();

  @override
  Future<CoffeeListing?> getListing(String listingId) async {
    if (_error != null) throw _error!;
    return _listing;
  }

  @override
  Future<String> createListing(CoffeeListing listing,
      {List<File>? images}) async => listing.listingId;

  @override
  Future<void> updateListing(CoffeeListing listing,
      {List<File>? newImages}) async {}

  @override
  Future<void> deleteListing(String listingId) async {}

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async =>
      const [];

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage(
          {int pageSize = 20, Object? startAfter}) async =>
      PaginatedResult(items: [], cursor: null, hasMore: false);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ListingDetailBloc — initial state', () {
    test('starts in ListingDetailInitial', () {
      final bloc = ListingDetailBloc(repository: _FakeListingRepository());
      expect(bloc.state, isA<ListingDetailInitial>());
      bloc.close();
    });
  });

  group('ListingDetailBloc — ListingDetailLoadRequested', () {
    test('emits ListingDetailLoaded when listing found', () async {
      final repo = _FakeListingRepository();
      final listing = _fakeListing();
      repo.setListing(listing);
      final bloc = ListingDetailBloc(repository: repo);

      bloc.add(const ListingDetailLoadRequested('listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingDetailLoaded>());
      expect((bloc.state as ListingDetailLoaded).listing, listing);

      bloc.close();
    });

    test('emits ListingDetailFailure when listing not found (null)', () async {
      final repo = _FakeListingRepository();
      repo.setListing(null);
      final bloc = ListingDetailBloc(repository: repo);

      bloc.add(const ListingDetailLoadRequested('missing'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingDetailFailure>());
      expect(
          (bloc.state as ListingDetailFailure).message, 'Listing not found');

      bloc.close();
    });

    test('emits ListingDetailFailure on exception', () async {
      final repo = _FakeListingRepository();
      repo.setError(Exception('network error'));
      final bloc = ListingDetailBloc(repository: repo);

      bloc.add(const ListingDetailLoadRequested('listing-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<ListingDetailFailure>());

      bloc.close();
    });
  });
}
