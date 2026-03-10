// lib/data/providers/listing_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/coffee_listing.dart';
import '../../domain/models/search_filters.dart';
import '../services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();

  List<CoffeeListing> _listings = [];
  List<CoffeeListing> _myListings = [];
  CoffeeListing? _currentListing;
  bool _isLoading = false;
  String? _error;

  List<CoffeeListing> get listings => _listings;
  List<CoffeeListing> get myListings => _myListings;
  CoffeeListing? get currentListing => _currentListing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create listing
  Future<String?> createListing(CoffeeListing listing, List<File>? images) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final listingId = await _listingService.createListing(listing);
      
      if (images != null && images.isNotEmpty) {
        final imageUrls = await _listingService.uploadImages(images, listingId);
        final updatedListing = listing.copyWith(listingId: listingId, images: imageUrls);
        await _listingService.updateListing(updatedListing);
      }

      _isLoading = false;
      notifyListeners();
      return listingId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update listing
  Future<bool> updateListing(CoffeeListing listing, List<File>? newImages) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (newImages != null && newImages.isNotEmpty) {
        final imageUrls = await _listingService.uploadImages(newImages, listing.listingId);
        final updatedListing = listing.copyWith(images: [...listing.images, ...imageUrls]);
        await _listingService.updateListing(updatedListing);
      } else {
        await _listingService.updateListing(listing);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete listing
  Future<bool> deleteListing(String listingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _listingService.deleteListing(listingId);
      _myListings.removeWhere((l) => l.listingId == listingId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load listing by ID
  Future<void> loadListing(String listingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentListing = await _listingService.getListing(listingId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load farmer's listings
  void loadFarmerListings(String farmerId) {
    _listingService.getFarmerListings(farmerId).listen((listings) {
      _myListings = listings;
      notifyListeners();
    });
  }

  // Search listings
  Future<void> searchListings(SearchFilters filters) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _listings = await _listingService.searchListings(filters);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all active listings
  void loadActiveListings() {
    _listingService.getActiveListings().listen((listings) {
      _listings = listings;
      notifyListeners();
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}