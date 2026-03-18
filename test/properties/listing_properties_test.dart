// Feature: brewmaster-marketplace
// Property tests for listing creation, search filters, quality/altitude validation,
// serialization round-trips, and status transitions.
//
// Validates: Requirements 2.1, 2.2, 2.5, 2.7, 4.1, 4.2, 4.3, 4.5
// Tasks: 5.2, 7.2
// Developer: Developer 2

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/validators/coffee_listing_validator.dart';

// ---------------------------------------------------------------------------
// Fake ListingRepository
// ---------------------------------------------------------------------------

class FakeListingRepository implements ListingRepository {
  final List<CoffeeListing> _store = [];
  bool shouldThrow = false;

  @override
  Future<String> createListing(CoffeeListing listing,
      {List<File>? images}) async {
    if (shouldThrow) throw Exception('network error');
    final id = 'listing_${_store.length + 1}';
    _store.add(listing.copyWith(listingId: id));
    return id;
  }

  @override
  Future<void> updateListing(CoffeeListing listing,
      {List<File>? newImages}) async {
    final idx = _store.indexWhere((l) => l.listingId == listing.listingId);
    if (idx >= 0) _store[idx] = listing;
  }

  @override
  Future<void> deleteListing(String listingId) async {
    _store.removeWhere((l) => l.listingId == listingId);
  }

  @override
  Future<CoffeeListing?> getListing(String listingId) async {
    try {
      return _store.firstWhere((l) => l.listingId == listingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      Stream.value(
          _store.where((l) => l.farmerId == farmerId).toList());

  @override
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value(
      _store.where((l) => l.status == ListingStatus.active).toList());

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    return _store.where((l) {
      if (filters.query != null &&
          filters.query!.isNotEmpty &&
          !l.variety.toLowerCase().contains(filters.query!.toLowerCase()) &&
          !l.location.toLowerCase().contains(filters.query!.toLowerCase())) {
        return false;
      }
      if (filters.method != null &&
          l.processingMethod.name != filters.method) {
        return false;
      }
      if (filters.minPrice != null && l.pricePerKg < filters.minPrice!) {
        return false;
      }
      if (filters.maxPrice != null && l.pricePerKg > filters.maxPrice!) {
        return false;
      }
      if (filters.minAltitude != null &&
          l.altitude < filters.minAltitude!) {
        return false;
      }
      if (filters.maxAltitude != null &&
          l.altitude > filters.maxAltitude!) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      PaginatedResult<CoffeeListing>(items: List.from(_store), hasMore: false);

  List<CoffeeListing> get all => List.unmodifiable(_store);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoffeeListing _makeListing({
  String listingId = '',
  String farmerId = 'farmer_1',
  String variety = 'Bourbon',
  double quantity = 100.0,
  double pricePerKg = 5.0,
  ProcessingMethod method = ProcessingMethod.washed,
  double altitude = 1500.0,
  double qualityScore = 85.0,
  ListingStatus status = ListingStatus.active,
}) {
  final now = DateTime(2024, 6, 1);
  return CoffeeListing(
    listingId: listingId,
    farmerId: farmerId,
    variety: variety,
    quantity: quantity,
    pricePerKg: pricePerKg,
    processingMethod: method,
    altitude: altitude,
    harvestDate: DateTime(2024, 3, 1),
    qualityScore: qualityScore,
    description: 'Test coffee',
    images: [],
    location: '-1.9441,29.8739',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Task 5.2 – listing creation & serialization properties
// ---------------------------------------------------------------------------

void main() {
  group('Property – Listing creation (Requirement 2.1)', () {
    test('createListing returns a non-empty id', () async {
      final repo = FakeListingRepository();
      final id = await repo.createListing(_makeListing());
      expect(id, isNotEmpty);
    });

    test('created listing is retrievable by id', () async {
      final repo = FakeListingRepository();
      final id = await repo.createListing(_makeListing(variety: 'Typica'));
      final fetched = await repo.getListing(id);
      expect(fetched, isNotNull);
      expect(fetched!.variety, equals('Typica'));
    });

    test('multiple listings get unique ids', () async {
      final repo = FakeListingRepository();
      final id1 = await repo.createListing(_makeListing());
      final id2 = await repo.createListing(_makeListing());
      expect(id1, isNot(equals(id2)));
    });

    test('error propagates when repository throws', () async {
      final repo = FakeListingRepository()..shouldThrow = true;
      expect(
        () => repo.createListing(_makeListing()),
        throwsException,
      );
    });
  });

  group('Property – Listing serialization (Requirement 2.1)', () {
    test('toJson / fromJson round-trip preserves all scalar fields', () {
      final original = _makeListing(
        listingId: 'm1',
        variety: 'Gesha',
        pricePerKg: 12.5,
        altitude: 1800.0,
        qualityScore: 92.0,
      );
      final json = original.toJson();
      final restored = CoffeeListing.fromJson(json);
      expect(restored.listingId, equals(original.listingId));
      expect(restored.variety, equals(original.variety));
      expect(restored.pricePerKg, equals(original.pricePerKg));
      expect(restored.altitude, equals(original.altitude));
      expect(restored.qualityScore, equals(original.qualityScore));
      expect(restored.processingMethod, equals(original.processingMethod));
      expect(restored.status, equals(original.status));
    });

    test('copyWith preserves unchanged fields', () {
      final original = _makeListing(quantity: 100.0, pricePerKg: 5.0);
      final updated = original.copyWith(quantity: 200.0);
      expect(updated.quantity, equals(200.0));
      expect(updated.pricePerKg, equals(5.0));
      expect(updated.variety, equals(original.variety));
    });

    test('status transitions are preserved in copyWith', () {
      final active = _makeListing(status: ListingStatus.active);
      final sold = active.copyWith(status: ListingStatus.sold);
      expect(sold.status, equals(ListingStatus.sold));
      expect(active.status, equals(ListingStatus.active));
    });
  });

  group('Property – Altitude validation (Requirement 2.6)', () {
    test('valid altitudes (800-2500m) return null error', () {
      expect(CoffeeListingValidator.validateAltitude(800), isNull);
      expect(CoffeeListingValidator.validateAltitude(1500), isNull);
      expect(CoffeeListingValidator.validateAltitude(2500), isNull);
    });

    test('altitude below 800m returns error', () {
      expect(CoffeeListingValidator.validateAltitude(799), isNotNull);
    });

    test('altitude above 2500m returns error', () {
      expect(CoffeeListingValidator.validateAltitude(2501), isNotNull);
    });

    test('zero or negative altitude returns error', () {
      expect(CoffeeListingValidator.validateAltitude(0), isNotNull);
      expect(CoffeeListingValidator.validateAltitude(-100), isNotNull);
    });
  });

  group('Property – Quality score validation (Requirement 8.4)', () {
    test('scores 0-100 are valid', () {
      expect(CoffeeListingValidator.validateQualityScore(0), isNull);
      expect(CoffeeListingValidator.validateQualityScore(85), isNull);
      expect(CoffeeListingValidator.validateQualityScore(100), isNull);
    });

    test('score above 100 returns error', () {
      expect(
          CoffeeListingValidator.validateQualityScore(101), isNotNull);
    });

    test('negative score returns error', () {
      expect(CoffeeListingValidator.validateQualityScore(-1), isNotNull);
    });
  });

  // Task 7.2 – search filter properties
  group('Property – Search filters (Requirement 4.2)', () {
    late FakeListingRepository repo;

    setUp(() async {
      repo = FakeListingRepository();
      await repo.createListing(
          _makeListing(variety: 'Bourbon', pricePerKg: 5.0, altitude: 1200));
      await repo.createListing(
          _makeListing(variety: 'Typica', pricePerKg: 8.0, altitude: 1800));
      await repo.createListing(_makeListing(
          variety: 'Gesha',
          pricePerKg: 15.0,
          altitude: 2200,
          method: ProcessingMethod.natural));
    });

    test('no filters returns all listings', () async {
      final results =
          await repo.searchListings(const SearchFilters());
      expect(results.length, equals(3));
    });

    test('variety filter narrows results', () async {
      final results = await repo
          .searchListings(const SearchFilters(query: 'Bourbon'));
      expect(results.length, equals(1));
      expect(results.first.variety, equals('Bourbon'));
    });

    test('price range filter excludes out-of-range listings', () async {
      final results = await repo.searchListings(
          const SearchFilters(minPrice: 6.0, maxPrice: 10.0));
      expect(results.every((l) => l.pricePerKg >= 6.0), isTrue);
      expect(results.every((l) => l.pricePerKg <= 10.0), isTrue);
    });

    test('altitude range filter works correctly', () async {
      final results = await repo.searchListings(
          const SearchFilters(minAltitude: 1500, maxAltitude: 2000));
      expect(results.every((l) => l.altitude >= 1500), isTrue);
      expect(results.every((l) => l.altitude <= 2000), isTrue);
    });

    test('processing method filter returns only matching method', () async {
      final results = await repo
          .searchListings(const SearchFilters(method: 'natural'));
      expect(results.length, equals(1));
      expect(results.first.processingMethod,
          equals(ProcessingMethod.natural));
    });

    test('combined filters apply all criteria', () async {
      final results = await repo.searchListings(
          const SearchFilters(minPrice: 5.0, maxPrice: 10.0, minAltitude: 1000));
      expect(results.every((l) => l.pricePerKg >= 5.0), isTrue);
      expect(results.every((l) => l.altitude >= 1000), isTrue);
    });

    test('filter returning no matches gives empty list', () async {
      final results = await repo
          .searchListings(const SearchFilters(query: 'SL28'));
      expect(results, isEmpty);
    });
  });

  group('Property – watchFarmerListings stream (Requirement 2.5)', () {
    test('stream returns only listings for given farmer', () async {
      final repo = FakeListingRepository();
      await repo.createListing(_makeListing(farmerId: 'farmer_A'));
      await repo.createListing(_makeListing(farmerId: 'farmer_B'));
      await repo.createListing(_makeListing(farmerId: 'farmer_A'));

      final listings =
          await repo.watchFarmerListings('farmer_A').first;
      expect(listings.length, equals(2));
      expect(listings.every((l) => l.farmerId == 'farmer_A'), isTrue);
    });

    test('watchActiveListings returns only active status', () async {
      final repo = FakeListingRepository();
      await repo.createListing(
          _makeListing(status: ListingStatus.active));
      await repo.createListing(
          _makeListing(status: ListingStatus.sold));
      await repo.createListing(
          _makeListing(status: ListingStatus.active));

      final active = await repo.watchActiveListings().first;
      expect(active.length, equals(2));
      expect(
          active.every((l) => l.status == ListingStatus.active), isTrue);
    });
  });

  group('Property – Listing CRUD (Requirement 2.7)', () {
    test('updateListing replaces the listing in store', () async {
      final repo = FakeListingRepository();
      final id = await repo.createListing(_makeListing(pricePerKg: 5.0));
      final existing = await repo.getListing(id);
      await repo.updateListing(existing!.copyWith(pricePerKg: 9.0));
      final updated = await repo.getListing(id);
      expect(updated!.pricePerKg, equals(9.0));
    });

    test('deleteListing removes listing from store', () async {
      final repo = FakeListingRepository();
      final id = await repo.createListing(_makeListing());
      await repo.deleteListing(id);
      final result = await repo.getListing(id);
      expect(result, isNull);
    });

    test('getListing returns null for unknown id', () async {
      final repo = FakeListingRepository();
      final result = await repo.getListing('non_existent');
      expect(result, isNull);
    });
  });
}
