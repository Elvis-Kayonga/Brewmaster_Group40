// lib/data/services/listing_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/coffee_listing.dart';
import '../../domain/models/search_filters.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create listing
  Future<String> createListing(CoffeeListing listing) async {
    final docRef = await _firestore.collection('listings').add(listing.toJson());
    return docRef.id;
  }

  // Get listing by ID
  Future<CoffeeListing?> getListing(String listingId) async {
    final doc = await _firestore.collection('listings').doc(listingId).get();
    return doc.exists ? CoffeeListing.fromJson(doc.data()!) : null;
  }

  // Update listing
  Future<void> updateListing(CoffeeListing listing) async {
    await _firestore.collection('listings').doc(listing.listingId).update(listing.toJson());
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    await _firestore.collection('listings').doc(listingId).delete();
  }

  // Get farmer's listings
  Stream<List<CoffeeListing>> getFarmerListings(String farmerId) {
    return _firestore
        .collection('listings')
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CoffeeListing.fromJson(doc.data())).toList());
  }

  // Search listings with filters
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    Query query = _firestore.collection('listings').where('status', isEqualTo: 'active');

    if (filters.variety != null) {
      query = query.where('variety', isEqualTo: filters.variety);
    }
    if (filters.processingMethod != null) {
      query = query.where('processingMethod', isEqualTo: filters.processingMethod);
    }
    if (filters.minPrice != null) {
      query = query.where('pricePerKg', isGreaterThanOrEqualTo: filters.minPrice);
    }
    if (filters.maxPrice != null) {
      query = query.where('pricePerKg', isLessThanOrEqualTo: filters.maxPrice);
    }
    if (filters.minAltitude != null) {
      query = query.where('altitude', isGreaterThanOrEqualTo: filters.minAltitude);
    }
    if (filters.maxAltitude != null) {
      query = query.where('altitude', isLessThanOrEqualTo: filters.maxAltitude);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => CoffeeListing.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // Upload images
  Future<List<String>> uploadImages(List<File> images, String listingId) async {
    final urls = <String>[];
    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref().child('listings/$listingId/image_$i.jpg');
      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Get all active listings
  Stream<List<CoffeeListing>> getActiveListings() {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CoffeeListing.fromJson(doc.data())).toList());
  }
}
