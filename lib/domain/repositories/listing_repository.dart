// Feature: brewmaster-marketplace
// Repository interface for listing CRUD, image upload, and search.
//
// Requirements: 2.1, 2.2, 2.5, 2.7, 2.8, 4.1, 4.2, 4.3, 16.1 (Clean Architecture)
// Developer: Developer 2

import 'dart:io';
import '../models/coffee_listing.dart';
import '../models/paginated_result.dart';
import '../models/search_filters.dart';

abstract class ListingRepository {
  /// Create a new listing, optionally uploading [images].
  /// Returns the generated listingId.
  Future<String> createListing(CoffeeListing listing, {List<File>? images});

  /// Update an existing listing, optionally uploading [newImages].
  Future<void> updateListing(CoffeeListing listing, {List<File>? newImages});

  /// Permanently delete a listing.
  Future<void> deleteListing(String listingId);

  /// Fetch a single listing by ID.
  Future<CoffeeListing?> getListing(String listingId);

  /// Real-time stream of the farmer's own listings.
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId);

  /// Real-time stream of all active listings.
  Stream<List<CoffeeListing>> watchActiveListings();

  /// One-shot filtered search.
  Future<List<CoffeeListing>> searchListings(SearchFilters filters);

  /// Paginated fetch of active listings ordered by createdAt descending.
  /// Pass [startAfter] from the previous [PaginatedResult.cursor] to get
  /// the next page.
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  });
}
