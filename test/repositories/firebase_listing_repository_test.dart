// Tests for FirebaseListingRepository
// Uses FakeFirebaseFirestore to test Firestore CRUD without real Firebase.
// Image upload (Cloudinary/HTTP) is skipped — that path requires a live network.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/data/repositories/firebase_listing_repository.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/search_filters.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CoffeeListing _makeListing({
  String listingId = 'listing-1',
  String farmerId = 'farmer-1',
  String? farmerName = 'Alice',
  String variety = 'Arabica',
  double quantity = 100.0,
  double pricePerKg = 5.0,
  ProcessingMethod processingMethod = ProcessingMethod.washed,
  double altitude = 1800.0,
  double qualityScore = 85.0,
  String description = 'Bright and fruity',
  List<String> images = const [],
  String location = 'Kenya',
  ListingStatus status = ListingStatus.active,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2024, 1, 15);
  return CoffeeListing(
    listingId: listingId,
    farmerId: farmerId,
    farmerName: farmerName,
    variety: variety,
    quantity: quantity,
    pricePerKg: pricePerKg,
    processingMethod: processingMethod,
    altitude: altitude,
    harvestDate: DateTime(2023, 10, 1),
    qualityScore: qualityScore,
    description: description,
    images: images,
    location: location,
    status: status,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('FirebaseListingRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseListingRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = FirebaseListingRepository(firestore: fakeFirestore);
    });

    // -------------------------------------------------------------------------
    // createListing
    // -------------------------------------------------------------------------

    group('createListing', () {
      test('adds document to listings collection and returns an id', () async {
        final listing = _makeListing();
        final id = await repo.createListing(listing);

        expect(id, isNotEmpty);
        final doc =
            await fakeFirestore.collection('listings').doc(id).get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['listingId'], equals(id));
        expect(doc.data()!['farmerId'], equals('farmer-1'));
      });

      test('creates listing without images and sets listingId field', () async {
        final listing = _makeListing(listingId: 'x');
        final id = await repo.createListing(listing);

        final doc =
            await fakeFirestore.collection('listings').doc(id).get();
        expect(doc.data()!['listingId'], equals(id));
        expect(doc.data()!.containsKey('imageUrls'), isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // getListing
    // -------------------------------------------------------------------------

    group('getListing', () {
      test('returns CoffeeListing when document exists', () async {
        final listing = _makeListing();
        final id = await repo.createListing(listing);

        final result = await repo.getListing(id);

        expect(result, isNotNull);
        expect(result!.farmerId, equals('farmer-1'));
        expect(result.variety, equals('Arabica'));
        expect(result.location, equals('Kenya'));
      });

      test('returns null when document does not exist', () async {
        final result = await repo.getListing('non-existent-id');
        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // updateListing
    // -------------------------------------------------------------------------

    group('updateListing', () {
      test('updates an existing document in Firestore', () async {
        final listing = _makeListing();
        final id = await repo.createListing(listing);

        final updated =
            listing.copyWith(listingId: id, pricePerKg: 9.99, variety: 'Bourbon');
        await repo.updateListing(updated);

        final doc =
            await fakeFirestore.collection('listings').doc(id).get();
        expect(
          (doc.data()!['askingPricePerKg'] as num).toDouble(),
          closeTo(9.99, 0.001),
        );
        expect(doc.data()!['coffeeVariety'], equals('Bourbon'));
      });

      test('updateListing without new images keeps existing images', () async {
        final listing = _makeListing(images: ['https://example.com/img1.jpg']);
        final id = await repo.createListing(listing);

        final updated = listing.copyWith(
          listingId: id,
          images: ['https://example.com/img1.jpg'],
        );
        await repo.updateListing(updated);

        final doc =
            await fakeFirestore.collection('listings').doc(id).get();
        final imgs = List<String>.from(doc.data()!['imageUrls'] as List);
        expect(imgs, contains('https://example.com/img1.jpg'));
      });
    });

    // -------------------------------------------------------------------------
    // deleteListing
    // -------------------------------------------------------------------------

    group('deleteListing', () {
      test('removes the document from Firestore', () async {
        final listing = _makeListing();
        final id = await repo.createListing(listing);

        await repo.deleteListing(id);

        final doc =
            await fakeFirestore.collection('listings').doc(id).get();
        expect(doc.exists, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // watchFarmerListings
    // -------------------------------------------------------------------------

    group('watchFarmerListings', () {
      test('emits listings for the given farmer only', () async {
        final id1 = await repo.createListing(
          _makeListing(listingId: 'a', farmerId: 'farmer-A'),
        );
        final id2 = await repo.createListing(
          _makeListing(listingId: 'b', farmerId: 'farmer-A'),
        );
        // Different farmer — should not appear.
        await repo.createListing(
          _makeListing(listingId: 'c', farmerId: 'farmer-B'),
        );

        // Patch listingId fields so round-trip works.
        await fakeFirestore
            .collection('listings')
            .doc(id1)
            .update({'listingId': id1});
        await fakeFirestore
            .collection('listings')
            .doc(id2)
            .update({'listingId': id2});

        final stream = repo.watchFarmerListings('farmer-A');
        final listings = await stream.first;

        expect(listings.length, equals(2));
        expect(listings.every((l) => l.farmerId == 'farmer-A'), isTrue);
      });

      test('emits empty list when no listings exist for farmer', () async {
        final stream = repo.watchFarmerListings('unknown-farmer');
        final listings = await stream.first;
        expect(listings, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // watchActiveListings
    // -------------------------------------------------------------------------

    group('watchActiveListings', () {
      test('emits only active listings', () async {
        final id1 = await repo.createListing(
          _makeListing(listingId: 'a1', status: ListingStatus.active),
        );
        await repo.createListing(
          _makeListing(listingId: 'b1', status: ListingStatus.sold),
        );

        await fakeFirestore
            .collection('listings')
            .doc(id1)
            .update({'listingId': id1});

        final stream = repo.watchActiveListings();
        final listings = await stream.first;

        expect(listings.every((l) => l.status == ListingStatus.active), isTrue);
      });

      test('emits empty list when no active listings', () async {
        await repo.createListing(
          _makeListing(listingId: 's1', status: ListingStatus.sold),
        );

        final stream = repo.watchActiveListings();
        final listings = await stream.first;
        expect(listings, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // searchListings
    // -------------------------------------------------------------------------

    group('searchListings', () {
      Future<void> seedActiveListings() async {
        final listingA = _makeListing(
          listingId: 'sa',
          farmerId: 'f1',
          variety: 'Arabica',
          pricePerKg: 4.0,
          altitude: 1500.0,
          location: 'Kenya',
          status: ListingStatus.active,
          processingMethod: ProcessingMethod.washed,
        );
        final listingB = _makeListing(
          listingId: 'sb',
          farmerId: 'f2',
          variety: 'Bourbon',
          pricePerKg: 8.0,
          altitude: 2200.0,
          location: 'Ethiopia',
          status: ListingStatus.active,
          processingMethod: ProcessingMethod.natural,
        );
        final listingC = _makeListing(
          listingId: 'sc',
          farmerId: 'f3',
          variety: 'Robusta',
          pricePerKg: 3.0,
          altitude: 900.0,
          location: 'Uganda',
          status: ListingStatus.sold, // not active
          processingMethod: ProcessingMethod.washed,
        );

        for (final l in [listingA, listingB, listingC]) {
          final id = await repo.createListing(l);
          await fakeFirestore
              .collection('listings')
              .doc(id)
              .update({'listingId': id});
        }
      }

      test('returns all active listings with empty filters', () async {
        await seedActiveListings();
        final results = await repo.searchListings(const SearchFilters());
        expect(results.every((l) => l.status == ListingStatus.active), isTrue);
        expect(results.length, equals(2));
      });

      test('filters by minPrice client-side', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(minPrice: 6.0),
        );
        expect(results.every((l) => l.pricePerKg >= 6.0), isTrue);
      });

      test('filters by maxPrice client-side', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(maxPrice: 5.0),
        );
        expect(results.every((l) => l.pricePerKg <= 5.0), isTrue);
      });

      test('filters by minAltitude client-side', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(minAltitude: 2000.0),
        );
        expect(results.every((l) => l.altitude >= 2000.0), isTrue);
      });

      test('filters by maxAltitude client-side', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(maxAltitude: 1600.0),
        );
        expect(results.every((l) => l.altitude <= 1600.0), isTrue);
      });

      test('filters by country client-side', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(country: 'Kenya'),
        );
        expect(
          results
              .every((l) => l.location.toLowerCase().contains('kenya')),
          isTrue,
        );
      });

      test('filters by query matching variety', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(query: 'bourbon'),
        );
        expect(
          results.every(
              (l) => l.variety.toLowerCase().contains('bourbon')),
          isTrue,
        );
      });

      test('returns empty list when no results match', () async {
        await seedActiveListings();
        final results = await repo.searchListings(
          const SearchFilters(query: 'xyz-no-match'),
        );
        expect(results, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // getListingPage
    // -------------------------------------------------------------------------

    group('getListingPage', () {
      test('returns first page of active listings', () async {
        for (var i = 0; i < 5; i++) {
          final id = await repo.createListing(
            _makeListing(
              listingId: 'p$i',
              farmerId: 'fp',
              status: ListingStatus.active,
              createdAt: DateTime(2024, 1, i + 1),
              updatedAt: DateTime(2024, 1, i + 1),
            ),
          );
          await fakeFirestore
              .collection('listings')
              .doc(id)
              .update({'listingId': id});
        }

        final page = await repo.getListingPage(pageSize: 3);

        expect(page.items.length, equals(3));
        expect(page.hasMore, isTrue);
        expect(page.cursor, isNotNull);
      });

      test('hasMore is false when results fit within pageSize', () async {
        for (var i = 0; i < 2; i++) {
          final id = await repo.createListing(
            _makeListing(
              listingId: 'q$i',
              farmerId: 'fq',
              status: ListingStatus.active,
            ),
          );
          await fakeFirestore
              .collection('listings')
              .doc(id)
              .update({'listingId': id});
        }

        final page = await repo.getListingPage(pageSize: 10);

        expect(page.hasMore, isFalse);
        expect(page.items.length, equals(2));
      });

      test('returns empty page when no active listings', () async {
        final page = await repo.getListingPage(pageSize: 20);
        expect(page.items, isEmpty);
        expect(page.hasMore, isFalse);
        expect(page.cursor, isNull);
      });
    });
  });
}
