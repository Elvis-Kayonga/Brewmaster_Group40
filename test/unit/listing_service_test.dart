// test/unit/listing_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';

void main() {
  group('CoffeeListing Model Tests', () {
    test('CoffeeListing.toJson() serializes correctly', () {
      final listing = CoffeeListing(
        listingId: 'list1',
        farmerId: 'farm1',
        variety: 'Bourbon',
        quantity: 100.0,
        pricePerKg: 5.5,
        processingMethod: ProcessingMethod.washed,
        altitude: 1500.0,
        harvestDate: DateTime(2024, 1, 15),
        qualityScore: 85.0,
        description: 'High quality coffee',
        images: ['image1.jpg'],
        location: {'latitude': -1.9, 'longitude': 29.8},
        status: ListingStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final json = listing.toJson();

      expect(json['listingId'], 'list1');
      expect(json['farmerId'], 'farm1');
      expect(json['variety'], 'Bourbon');
      expect(json['quantity'], 100.0);
      expect(json['pricePerKg'], 5.5);
      expect(json['processingMethod'], 'washed');
      expect(json['altitude'], 1500.0);
      expect(json['qualityScore'], 85.0);
      expect(json['status'], 'active');
    });

    test('CoffeeListing.fromJson() deserializes correctly', () {
      final json = {
        'listingId': 'list1',
        'farmerId': 'farm1',
        'variety': 'Bourbon',
        'quantity': 100.0,
        'pricePerKg': 5.5,
        'processingMethod': 'washed',
        'altitude': 1500.0,
        'harvestDate': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'qualityScore': 85.0,
        'description': 'High quality coffee',
        'images': ['image1.jpg'],
        'location': {'latitude': -1.9, 'longitude': 29.8},
        'status': 'active',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      };

      final listing = CoffeeListing.fromJson(json);

      expect(listing.listingId, 'list1');
      expect(listing.farmerId, 'farm1');
      expect(listing.variety, 'Bourbon');
      expect(listing.quantity, 100.0);
      expect(listing.pricePerKg, 5.5);
      expect(listing.processingMethod, ProcessingMethod.washed);
      expect(listing.altitude, 1500.0);
      expect(listing.qualityScore, 85.0);
      expect(listing.status, ListingStatus.active);
    });

    test('CoffeeListing.copyWith() creates new instance with updated fields', () {
      final original = CoffeeListing(
        listingId: 'list1',
        farmerId: 'farm1',
        variety: 'Bourbon',
        quantity: 100.0,
        pricePerKg: 5.5,
        processingMethod: ProcessingMethod.washed,
        altitude: 1500.0,
        harvestDate: DateTime(2024, 1, 15),
        qualityScore: 85.0,
        description: 'High quality coffee',
        images: ['image1.jpg'],
        location: {'latitude': -1.9, 'longitude': 29.8},
        status: ListingStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final updated = original.copyWith(
        quantity: 150.0,
        pricePerKg: 6.0,
        status: ListingStatus.sold,
      );

      expect(updated.quantity, 150.0);
      expect(updated.pricePerKg, 6.0);
      expect(updated.status, ListingStatus.sold);
      expect(updated.variety, 'Bourbon');
      expect(updated.farmerId, 'farm1');
    });
  });
}
