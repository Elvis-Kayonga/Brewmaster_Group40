// Feature: brewmaster-marketplace
// Firebase implementation of ListingRepository.
// All Firestore / Storage imports stay in this file — never in UI or BLoC.
//
// Requirements: 2.1, 2.2, 2.5, 2.7, 2.8, 4.1, 4.2, 4.3, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../config/cloudinary_config.dart';
import '../../domain/models/coffee_listing.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/repositories/listing_repository.dart';

class FirebaseListingRepository implements ListingRepository {
  final FirebaseFirestore _firestore;

  FirebaseListingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
      await docRef.update({'imageUrls': urls, 'listingId': docRef.id});
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
        .snapshots()
        .map((s) {
          final list =
              s.docs.map((d) => CoffeeListing.fromJson(d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  @override
  Stream<List<CoffeeListing>> watchActiveListings() {
    return _col
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((s) async {
          final list =
              s.docs.map((d) => CoffeeListing.fromJson(d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return _enrichWithFarmerNames(list);
        });
  }

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async {
    // Only use processingMethod as a Firestore filter (single equality —
    // no composite index needed). All range and text filters are applied
    // client-side to avoid Firestore index requirements.
    Query<Map<String, dynamic>> query =
        _col.where('status', isEqualTo: 'active');

    if (filters.method != null) {
      query = query.where('processingMethod', isEqualTo: filters.method);
    }

    var results = (await query.get())
        .docs
        .map((d) => CoffeeListing.fromJson(d.data()))
        .toList();

    // Client-side range and text filtering
    if (filters.minPrice != null) {
      results =
          results.where((l) => l.pricePerKg >= filters.minPrice!).toList();
    }
    if (filters.maxPrice != null) {
      results =
          results.where((l) => l.pricePerKg <= filters.maxPrice!).toList();
    }
    if (filters.minAltitude != null) {
      results =
          results.where((l) => l.altitude >= filters.minAltitude!).toList();
    }
    if (filters.maxAltitude != null) {
      results =
          results.where((l) => l.altitude <= filters.maxAltitude!).toList();
    }
    if (filters.country != null) {
      final c = filters.country!.toLowerCase();
      results = results
          .where((l) => l.location.toLowerCase().contains(c))
          .toList();
    }
    if (filters.query != null && filters.query!.isNotEmpty) {
      final q = filters.query!.toLowerCase();
      results = results
          .where((l) =>
              l.variety.toLowerCase().contains(q) ||
              l.location.toLowerCase().contains(q) ||
              (l.farmerName?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return _enrichWithFarmerNames(results);
  }

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _col
        .where('status', isEqualTo: 'active')
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

  /// For listings that have no [farmerName] stored, batch-fetch the farmer's
  /// displayName from the `users` collection and back-fill it in memory.
  Future<List<CoffeeListing>> _enrichWithFarmerNames(
      List<CoffeeListing> listings) async {
    final missing = listings.where((l) => l.farmerName == null).toList();
    if (missing.isEmpty) return listings;

    final uniqueIds = missing.map((l) => l.farmerId).toSet();
    final nameMap = <String, String>{};
    for (final id in uniqueIds) {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        nameMap[id] = doc.data()?['displayName'] as String? ?? '';
      }
    }

    return listings.map((l) {
      if (l.farmerName != null) return l;
      final name = nameMap[l.farmerId];
      return name != null && name.isNotEmpty ? l.copyWith(farmerName: name) : l;
    }).toList();
  }

  Future<List<String>> _uploadImages(
      List<File> images, String listingId) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['public_id'] = 'listings/$listingId/image_$i'
        ..files.add(await http.MultipartFile.fromPath('file', images[i].path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) throw Exception('Image upload failed');
      final data = jsonDecode(body) as Map<String, dynamic>;
      urls.add(data['secure_url'] as String);
    }
    return urls;
  }
}
