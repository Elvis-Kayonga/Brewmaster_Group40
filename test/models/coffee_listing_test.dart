/// Unit tests for CoffeeListing model
///
/// Testing patterns:
/// 1. Object creation and initialization
/// 2. JSON serialization and deserialization
/// 3. copyWith functionality
/// 4. Data validation and constraints
/// 5. Edge cases and boundary conditions
///
/// Requirements: 2.1, 2.6, 8.4, 15.1, 16.1
/// Developer: Developer 2
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';

void main() {
  group('CoffeeListing Model Tests', () {
    late CoffeeListing testListing;
    late DateTime testHarvestDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testHarvestDate = DateTime(2024, 6, 15);
      testCreatedAt = DateTime(2024, 7, 1, 10, 30);
      testUpdatedAt = DateTime(2024, 7, 5, 14, 45);

      testListing = CoffeeListing(
        listingId: 'listing-123',
        farmerId: 'farmer-456',
        variety: 'Arabica SL28',
        quantity: 500.0,
        pricePerKg: 850.0,
        processingMethod: ProcessingMethod.washed,
        altitude: 1800.0,
        harvestDate: testHarvestDate,
        qualityScore: 87.5,
        description: 'Premium quality Arabica coffee from Mt. Kenya region',
        images: ['image1.jpg', 'image2.jpg', 'image3.jpg'],
        location: 'Kirinyaga County, Kenya',
        status: ListingStatus.active,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
    });

    group('Object Creation Tests', () {
      test('Should create CoffeeListing with all required fields', () {
        expect(testListing.listingId, equals('listing-123'));
        expect(testListing.farmerId, equals('farmer-456'));
        expect(testListing.variety, equals('Arabica SL28'));
        expect(testListing.quantity, equals(500.0));
        expect(testListing.pricePerKg, equals(850.0));
        expect(testListing.processingMethod, equals(ProcessingMethod.washed));
        expect(testListing.altitude, equals(1800.0));
        expect(testListing.harvestDate, equals(testHarvestDate));
        expect(testListing.qualityScore, equals(87.5));
        expect(testListing.description, contains('Premium quality'));
        expect(testListing.images, hasLength(3));
        expect(testListing.location, equals('Kirinyaga County, Kenya'));
        expect(testListing.status, equals(ListingStatus.active));
        expect(testListing.createdAt, equals(testCreatedAt));
        expect(testListing.updatedAt, equals(testUpdatedAt));
      });

      test('Should create listing with different processing methods', () {
        final washedListing = testListing.copyWith(
          processingMethod: ProcessingMethod.washed,
        );
        final naturalListing = testListing.copyWith(
          processingMethod: ProcessingMethod.natural,
        );
        final honeyListing = testListing.copyWith(
          processingMethod: ProcessingMethod.honey,
        );

        expect(washedListing.processingMethod, equals(ProcessingMethod.washed));
        expect(
          naturalListing.processingMethod,
          equals(ProcessingMethod.natural),
        );
        expect(honeyListing.processingMethod, equals(ProcessingMethod.honey));
      });

      test('Should create listing with different statuses', () {
        final draftListing = testListing.copyWith(status: ListingStatus.draft);
        final activeListing = testListing.copyWith(
          status: ListingStatus.active,
        );
        final soldListing = testListing.copyWith(status: ListingStatus.sold);
        final expiredListing = testListing.copyWith(
          status: ListingStatus.expired,
        );

        expect(draftListing.status, equals(ListingStatus.draft));
        expect(activeListing.status, equals(ListingStatus.active));
        expect(soldListing.status, equals(ListingStatus.sold));
        expect(expiredListing.status, equals(ListingStatus.expired));
      });
    });

    group('JSON Serialization Tests', () {
      test('Should convert CoffeeListing to JSON correctly', () {
        final json = testListing.toJson();

        expect(json['listingId'], equals('listing-123'));
        expect(json['farmerId'], equals('farmer-456'));
        expect(json['coffeeVariety'], equals('Arabica SL28'));
        expect(json['quantityKg'], equals(500.0));
        expect(json['askingPricePerKg'], equals(850.0));
        expect(json['processingMethod'], equals('washed'));
        expect(json['altitude'], equals(1800.0));
        expect(json['harvestDate'], equals(testHarvestDate.toIso8601String()));
        expect(json['cuppingScore'], equals(87.5));
        expect(json['flavorNotes'], contains('Premium quality'));
        expect(json['imageUrls'], hasLength(3));
        expect(json['location'], equals('Kirinyaga County, Kenya'));
        expect(json['status'], equals('active'));
        expect(json['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(json['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('Should create CoffeeListing from JSON correctly', () {
        final json = testListing.toJson();
        final recreatedListing = CoffeeListing.fromJson(json);

        expect(recreatedListing.listingId, equals(testListing.listingId));
        expect(recreatedListing.farmerId, equals(testListing.farmerId));
        expect(recreatedListing.variety, equals(testListing.variety));
        expect(recreatedListing.quantity, equals(testListing.quantity));
        expect(recreatedListing.pricePerKg, equals(testListing.pricePerKg));
        expect(
          recreatedListing.processingMethod,
          equals(testListing.processingMethod),
        );
        expect(recreatedListing.altitude, equals(testListing.altitude));
        expect(
          recreatedListing.harvestDate.toIso8601String(),
          equals(testListing.harvestDate.toIso8601String()),
        );
        expect(recreatedListing.qualityScore, equals(testListing.qualityScore));
        expect(recreatedListing.description, equals(testListing.description));
        expect(recreatedListing.images, equals(testListing.images));
        expect(recreatedListing.location, equals(testListing.location));
        expect(recreatedListing.status, equals(testListing.status));
      });

      test('Should handle empty images list in JSON', () {
        final listing = testListing.copyWith(images: []);
        final json = listing.toJson();
        final recreated = CoffeeListing.fromJson(json);

        expect(recreated.images, isEmpty);
      });

      test('Should handle integer quantity as num in JSON', () {
        final json = testListing.toJson();
        json['quantityKg'] = 500; // Integer instead of double
        json['askingPricePerKg'] = 850;
        json['altitude'] = 1800;
        json['cuppingScore'] = 87;

        final recreated = CoffeeListing.fromJson(json);

        expect(recreated.quantity, equals(500.0));
        expect(recreated.pricePerKg, equals(850.0));
        expect(recreated.altitude, equals(1800.0));
        expect(recreated.qualityScore, equals(87.0));
      });
    });

    group('copyWith Tests', () {
      test('Should copy listing with updated fields', () {
        final updated = testListing.copyWith(
          quantity: 600.0,
          pricePerKg: 900.0,
          status: ListingStatus.sold,
        );

        expect(updated.quantity, equals(600.0));
        expect(updated.pricePerKg, equals(900.0));
        expect(updated.status, equals(ListingStatus.sold));
        
        // Unchanged fields should remain the same
        expect(updated.listingId, equals(testListing.listingId));
        expect(updated.farmerId, equals(testListing.farmerId));
        expect(updated.variety, equals(testListing.variety));
      });

      test('Should copy listing without changing original', () {
        final original = testListing;
        final updated = testListing.copyWith(quantity: 600.0);

        expect(original.quantity, equals(500.0));
        expect(updated.quantity, equals(600.0));
      });

      test('Should copy with null values where appropriate', () {
        final updated = testListing.copyWith();

        expect(updated.listingId, equals(testListing.listingId));
        expect(updated.quantity, equals(testListing.quantity));
        expect(updated.status, equals(testListing.status));
      });
    });

    group('Business Logic Tests', () {
      test('Should calculate total value correctly', () {
        final totalValue = testListing.quantity * testListing.pricePerKg;
        expect(totalValue, equals(425000.0)); // 500 * 850
      });

      test('Should have realistic altitude for coffee', () {
        expect(testListing.altitude, greaterThanOrEqualTo(800.0));
        expect(testListing.altitude, lessThanOrEqualTo(2500.0));
      });

      test('Should have quality score between 0 and 100', () {
        expect(testListing.qualityScore, greaterThanOrEqualTo(0.0));
        expect(testListing.qualityScore, lessThanOrEqualTo(100.0));
      });

      test('Should have quantity greater than 0', () {
        expect(testListing.quantity, greaterThan(0.0));
      });

      test('Should have price greater than 0', () {
        expect(testListing.pricePerKg, greaterThan(0.0));
      });

      test('Should have harvest date before or equal to creation date', () {
        expect(
          testListing.harvestDate.isBefore(testListing.createdAt) ||
              testListing.harvestDate.isAtSameMomentAs(testListing.createdAt),
          isTrue,
        );
      });

      test('Should have updatedAt equal to or after createdAt', () {
        expect(
          testListing.updatedAt.isAfter(testListing.createdAt) ||
              testListing.updatedAt.isAtSameMomentAs(testListing.createdAt),
          isTrue,
        );
      });
    });

    group('Edge Cases and Boundary Tests', () {
      test('Should handle minimum quantity', () {
        final minListing = testListing.copyWith(quantity: 0.1);
        expect(minListing.quantity, equals(0.1));
      });

      test('Should handle large quantity', () {
        final largeListing = testListing.copyWith(quantity: 10000.0);
        expect(largeListing.quantity, equals(10000.0));
      });

      test('Should handle very low price', () {
        final lowPriceListing = testListing.copyWith(pricePerKg: 1.0);
        expect(lowPriceListing.pricePerKg, equals(1.0));
      });

      test('Should handle very high price', () {
        final highPriceListing = testListing.copyWith(pricePerKg: 5000.0);
        expect(highPriceListing.pricePerKg, equals(5000.0));
      });

      test('Should handle minimum altitude', () {
        final lowAltitude = testListing.copyWith(altitude: 800.0);
        expect(lowAltitude.altitude, equals(800.0));
      });

      test('Should handle maximum altitude', () {
        final highAltitude = testListing.copyWith(altitude: 2500.0);
        expect(highAltitude.altitude, equals(2500.0));
      });

      test('Should handle quality score 0', () {
        final zeroQuality = testListing.copyWith(qualityScore: 0.0);
        expect(zeroQuality.qualityScore, equals(0.0));
      });

      test('Should handle quality score 100', () {
        final perfectQuality = testListing.copyWith(qualityScore: 100.0);
        expect(perfectQuality.qualityScore, equals(100.0));
      });

      test('Should handle empty description', () {
        final noDescription = testListing.copyWith(description: '');
        expect(noDescription.description, equals(''));
      });

      test('Should handle very long description', () {
        final longDescription = 'A' * 1000;
        final longDescListing = testListing.copyWith(
          description: longDescription,
        );
        expect(longDescListing.description, hasLength(1000));
      });

      test('Should handle single image', () {
        final singleImage = testListing.copyWith(images: ['single.jpg']);
        expect(singleImage.images, hasLength(1));
      });

      test('Should handle many images', () {
        final manyImages = List.generate(10, (i) => 'image$i.jpg');
        final manyImagesListing = testListing.copyWith(images: manyImages);
        expect(manyImagesListing.images, hasLength(10));
      });
    });

    group('Variety Tests', () {
      test('Should handle common coffee varieties', () {
        final varieties = [
          'Arabica',
          'Robusta',
          'SL28',
          'SL34',
          'Ruiru 11',
          'Batian',
          'K7',
          'Blue Mountain',
        ];

        for (final variety in varieties) {
          final listing = testListing.copyWith(variety: variety);
          expect(listing.variety, equals(variety));
        }
      });
    });

    group('Location Tests', () {
      test('Should handle different location formats', () {
        final locations = [
          'Kirinyaga County, Kenya',
          'Mt. Kenya Region',
          'Nyeri',
          'Kiambu County',
          'Murang\'a',
        ];

        for (final location in locations) {
          final listing = testListing.copyWith(location: location);
          expect(listing.location, equals(location));
        }
      });
    });

    group('Status Workflow Tests', () {
      test('Should transition from draft to active', () {
        final draft = testListing.copyWith(status: ListingStatus.draft);
        final active = draft.copyWith(status: ListingStatus.active);

        expect(draft.status, equals(ListingStatus.draft));
        expect(active.status, equals(ListingStatus.active));
      });

      test('Should transition from active to sold', () {
        final active = testListing.copyWith(status: ListingStatus.active);
        final sold = active.copyWith(status: ListingStatus.sold);

        expect(active.status, equals(ListingStatus.active));
        expect(sold.status, equals(ListingStatus.sold));
      });

      test('Should handle expired listings', () {
        final expired = testListing.copyWith(status: ListingStatus.expired);
        expect(expired.status, equals(ListingStatus.expired));
      });
    });

    group('Image URL Tests', () {
      test('Should handle image URLs with different formats', () {
        final imageUrls = [
          'https://example.com/image1.jpg',
          'file:///local/image.png',
          'image.jpg',
          'https://cloudinary.com/v1/image123',
        ];

        final listing = testListing.copyWith(images: imageUrls);
        expect(listing.images, equals(imageUrls));
        expect(listing.images, hasLength(4));
      });
    });
  });
}
