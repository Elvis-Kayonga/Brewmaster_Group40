import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/coffee_listing.dart';
import '../../domain/models/search_filters.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new listing
  Future<String> createListing(CoffeeListing listing) async {
    try {
      final docRef = await _firestore.collection('listings').add(listing.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  // Get a single listing by ID
  Future<CoffeeListing?> getListing(String listingId) async {
    try {
      final doc = await _firestore.collection('listings').doc(listingId).get();
      if (doc.exists) {
        return CoffeeListing.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get listing: $e');
    }
  }

  // Update a listing
  Future<void> updateListing(String listingId, CoffeeListing listing) async {
    try {
      await _firestore.collection('listings').doc(listingId).update(listing.toJson());
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  // Get farmer's listings as a stream
  Stream<List<CoffeeListing>> getFarmerListings(String farmerId) {
    return _firestore
        .collection('listings')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CoffeeListing.fromJson(doc.data()))
          .toList();
    });
  }

  // Get active listings as a stream
  Stream<List<CoffeeListing>> getActiveListings() {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CoffeeListing.fromJson(doc.data()))
          .toList();
    });
  }

  // Search listings with filters
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    try {
      Query query = _firestore.collection('listings');

      if (filters.query != null && filters.query!.isNotEmpty) {
        query = query.where('coffeeVariety', isEqualTo: filters.query);
      }

      if (filters.method != null && filters.method!.isNotEmpty) {
        query = query.where('processingMethod', isEqualTo: filters.method);
      }

      if (filters.minPrice != null) {
        query = query.where('askingPricePerKg', isGreaterThanOrEqualTo: filters.minPrice);
      }

      if (filters.maxPrice != null) {
        query = query.where('askingPricePerKg', isLessThanOrEqualTo: filters.maxPrice);
      }

      if (filters.minAltitude != null) {
        query = query.where('altitude', isGreaterThanOrEqualTo: filters.minAltitude);
      }

      if (filters.maxAltitude != null) {
        query = query.where('altitude', isLessThanOrEqualTo: filters.maxAltitude);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CoffeeListing.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search listings: $e');
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> uploadImages(List<File> imageFiles, String listingId) async {
    try {
      final List<String> imageUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final ref = _storage.ref('listings/$listingId/image_$i.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }
}
