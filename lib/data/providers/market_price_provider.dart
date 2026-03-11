import 'package:flutter/material.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/market_price.dart';
import '../services/market_price_service.dart';

/// State management for market price data.
///
/// Exposes market price lists to the UI layer and handles loading / error
/// states.  Offline caching is provided transparently by Firestore's built-in
/// persistence; this provider surfaces the last-sync timestamp so the UI can
/// inform users of data freshness (Requirement 3.5).
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 16.1 (Clean Architecture),
///               16.2 (Provider state management)
/// Developer: Developer 5
class MarketPriceProvider extends ChangeNotifier {
  MarketPriceProvider({MarketPriceService? service})
      : _service = service ?? MarketPriceService();

  final MarketPriceService _service;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  List<MarketPrice> _prices = [];
  bool _isLoading = false;
  String? _error;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All loaded market prices.
  List<MarketPrice> get prices => List.unmodifiable(_prices);

  bool get isLoading => _isLoading;

  String? get error => _error;

  /// When the data was last fetched; `null` before the first fetch.
  /// Displayed to users when the app is offline (Requirement 3.5,
  /// Property 13).
  DateTime? get lastSyncTime => _service.getLastSyncTime();

  /// Returns `true` when at least one price has been loaded.
  bool get hasPrices => _prices.isNotEmpty;

  /// Returns the unique set of variety names from the loaded prices.
  List<String> get varieties =>
      _prices.map((p) => p.variety).toSet().toList()..sort();

  // ---------------------------------------------------------------------------
  // Methods
  // ---------------------------------------------------------------------------

  /// Loads all market prices. Silently uses the Firestore offline cache when
  /// connectivity is unavailable.
  Future<void> loadMarketPrices() async {
    _setLoading(true);
    _error = null;
    try {
      _prices = await _service.getMarketPrices();
    } catch (e) {
      _error = 'Failed to load market prices. '
          'Showing cached data if available.';
    } finally {
      _setLoading(false);
    }
  }

  /// Forces a fresh sync from Firestore.
  ///
  /// Should be called at least once per day (Requirement 3.4).
  Future<void> syncMarketPrices() async {
    _setLoading(true);
    _error = null;
    try {
      _prices = await _service.syncMarketPrices();
    } catch (e) {
      _error = 'Sync failed. Please check your connection and try again.';
    } finally {
      _setLoading(false);
    }
  }

  /// Returns prices for [variety], optionally filtered by [grade].
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async {
    // Try to return from in-memory state first to avoid extra Firestore reads
    final cached = _prices.where((p) {
      final matchVariety =
          p.variety.toLowerCase() == variety.toLowerCase();
      final matchGrade = grade == null || p.grade == grade;
      return matchVariety && matchGrade;
    }).toList();

    if (cached.isNotEmpty) return cached;

    // Fall back to a Firestore query when the cache is empty
    return _service.getPricesForVariety(variety, grade: grade);
  }

  /// Convenience method used by [PriceGuidanceWidget].
  Future<MarketPrice?> getPriceForVariety(
    String variety,
    QualityGrade grade,
  ) async {
    final results =
        await getPricesForVariety(variety, grade: grade);
    return results.isEmpty ? null : results.first;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
