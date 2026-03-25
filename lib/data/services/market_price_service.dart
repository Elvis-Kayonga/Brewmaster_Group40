import 'package:cloud_firestore/cloud_firestore.dart';

import 'coffee_price_api_service.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/market_price.dart';

/// Fetches and caches market price data from Firestore.
///
/// Reads from the [marketPrices] Firestore collection (read-only for clients –
/// see firestore.rules). Firestore's built-in offline persistence provides
/// automatic caching when connectivity is unavailable (Requirement 3.5).
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class MarketPriceService {
  MarketPriceService({
    FirebaseFirestore? firestore,
    CoffeePriceApiService? coffeePriceApi,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _coffeePriceApi = coffeePriceApi ?? CoffeePriceApiService();

  final FirebaseFirestore _firestore;
  final CoffeePriceApiService _coffeePriceApi;

  /// Tracks the timestamp of the most recent successful fetch.
  DateTime? _lastSyncTime;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('marketPrices');

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all market price records from Firestore (or the local cache when
  /// offline).  Results are ordered by variety then grade for consistent display.
  ///
  /// Property 12: every record contains variety, grade, low/avg/high price,
  /// currency, and timestamp fields.
  Future<List<MarketPrice>> getMarketPrices() async {
    final snapshot = await _collection.orderBy('variety').get();
    final prices = snapshot.docs.map(MarketPrice.fromFirestore).toList();
    _lastSyncTime = DateTime.now();
    return prices;
  }

  /// Returns prices for a specific [variety].  If [grade] is provided, returns
  /// only the record for that grade; otherwise returns all grades for the
  /// variety.
  ///
  /// Property 7: when a variety is selected on the listing form, the system
  /// fetches and returns the corresponding price data.
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async {
    Query<Map<String, dynamic>> query = _collection.where(
      'variety',
      isEqualTo: variety,
    );
    if (grade != null) {
      query = query.where('grade', isEqualTo: grade.toJson());
    }
    final snapshot = await query.get();
    final prices = snapshot.docs.map(MarketPrice.fromFirestore).toList();
    _lastSyncTime = DateTime.now();
    return prices;
  }

  /// Convenience method: returns a single [MarketPrice] for a [variety] and
  /// [grade], or `null` when no matching record exists.
  Future<MarketPrice?> getPriceForVariety(
    String variety,
    QualityGrade grade,
  ) async {
    final prices = await getPricesForVariety(variety, grade: grade);
    return prices.isEmpty ? null : prices.first;
  }

  /// Forces a fresh fetch from Firestore (bypasses any in-memory state held by
  /// providers). Call at least once per day to satisfy Requirement 3.4.
  Future<List<MarketPrice>> syncMarketPrices() async {
    return syncDailyPrices();
  }

  /// Fetches live daily prices from the external API and upserts them into
  /// Firestore, then returns the latest stored records.
  Future<List<MarketPrice>> syncDailyPrices() async {
    final dailyPrices = await _coffeePriceApi.fetchDailyPrices();
    final batch = _firestore.batch();

    for (final price in dailyPrices) {
      final docRef = _collection.doc(price.id);
      batch.set(docRef, price.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
    _lastSyncTime = DateTime.now();
    return getMarketPrices();
  }

  /// Returns the timestamp of the last successful data fetch, or `null` when
  /// no fetch has occurred yet in this session.
  ///
  /// Property 13: displayed alongside cached data when the user is offline.
  DateTime? getLastSyncTime() => _lastSyncTime;

  /// Returns a real-time stream of all market prices, updating whenever
  /// Firestore data changes.
  Stream<List<MarketPrice>> watchMarketPrices() {
    return _collection
        .orderBy('variety')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MarketPrice.fromFirestore).toList(),
        );
  }
}
