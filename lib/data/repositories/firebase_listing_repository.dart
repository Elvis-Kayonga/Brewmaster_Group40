// Feature: brewmaster-marketplace
// Firebase implementation of ListingRepository.
// All Firestore / Storage imports stay in this file — never in UI or BLoC.
//
// Requirements: 2.1, 2.2, 2.5, 2.7, 2.8, 4.1, 4.2, 4.3, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/coffee_listing.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/repositories/listing_repository.dart';

class FirebaseListingRepository implements ListingRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseListingRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('listings');

  @override
  Future<String> createListing(
    CoffeeListing listing, {
    List<File>? images,
  }) async {
    final docRef = await _col.add(listing.toJson());
    if (images != null && images.isNotEmpty) {
      final urls = await _uploadImages(images, docRef.id);
      await docRef.update({'images': urls, 'listingId': docRef.id});
    } else {
      await docRef.update({'listingId': docRef.id});
    }
    return docRef.id;
  }

  @override
  Future<void> updateListing(
    CoffeeListing listing, {
    List<File>? newImages,
  }) async {
    List<String> images = listing.images;
    if (newImages != null && newImages.isNotEmpty) {
      final uploaded = await _uploadImages(newImages, listing.listingId);
      images = [...images, ...uploaded];
    }
    await _col.doc(listing.listingId).update(
          listing.copyWith(images: images).toJson(),
        );
  }

  @override
  Future<void> deleteListing(String listingId) async {
    await _col.doc(listingId).delete();
  }

  @override
  Future<CoffeeListing?> getListing(String listingId) async {
    final doc = await _col.doc(listingId).get();
    if (!doc.exists) return null;
    return CoffeeListing.fromJson(doc.data()!);
  }

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) {
    return _col
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CoffeeListing.fromJson(d.data())).toList());
  }

  @override
  Stream<List<CoffeeListing>> watchActiveListings() {
    return _col
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CoffeeListing.fromJson(d.data())).toList());
  }

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    Query<Map<String, dynamic>> query =
        _col.where('status', isEqualTo: 'active');

    if (filters.variety != null) {
      query = query.where('variety', isEqualTo: filters.variety);
    }
    if (filters.method != null) {
      query = query.where('processingMethod', isEqualTo: filters.method);
    }
    if (filters.minPrice != null) {
      query = query.where('pricePerKg',
          isGreaterThanOrEqualTo: filters.minPrice);
    }
    if (filters.maxPrice != null) {
      query =
          query.where('pricePerKg', isLessThanOrEqualTo: filters.maxPrice);
    }
    if (filters.minAltitude != null) {
      query = query.where('altitude',
          isGreaterThanOrEqualTo: filters.minAltitude);
    }
    if (filters.maxAltitude != null) {
      query =
          query.where('altitude', isLessThanOrEqualTo: filters.maxAltitude);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => CoffeeListing.fromJson(d.data()))
        .toList();
  }

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _col
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(pageSize + 1); // fetch one extra to detect hasMore

    if (startAfter is DocumentSnapshot) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore ? snapshot.docs.sublist(0, pageSize) : snapshot.docs;

    return PaginatedResult<CoffeeListing>(
      items: docs.map((d) => CoffeeListing.fromJson(d.data())).toList(),
      hasMore: hasMore,
      cursor: docs.isNotEmpty ? docs.last : null,
    );
  }

  Future<List<String>> _uploadImages(
      List<File> images, String listingId) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final ref =
          _storage.ref().child('listings/$listingId/image_$i.jpg');
      await ref.putFile(images[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }
}
