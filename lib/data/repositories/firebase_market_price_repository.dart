import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/market_price.dart';
import '../../domain/repositories/market_price_repository.dart';

/// Firebase implementation of [MarketPriceRepository].
///
/// Reads from the [marketPrices] Firestore collection. Firestore's built-in
/// offline persistence provides automatic caching when connectivity is
/// unavailable (Requirement 3.5).
///
/// Requirements: 3.1, 3.2, 3.4, 3.5
/// Developer: Developer 5
class FirebaseMarketPriceRepository implements MarketPriceRepository {
  FirebaseMarketPriceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DateTime? _lastSyncTime;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('marketPrices');

  @override
  DateTime? get lastSyncTime => _lastSyncTime;

  @override
  Future<List<MarketPrice>> getMarketPrices() async {
    final snapshot = await _collection.orderBy('variety').get();
    _lastSyncTime = DateTime.now();
    return snapshot.docs.map(MarketPrice.fromFirestore).toList();
  }

  @override
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  }) async {
    Query<Map<String, dynamic>> query =
        _collection.where('variety', isEqualTo: variety);
    if (grade != null) {
      query = query.where('grade', isEqualTo: grade.toJson());
    }
    final snapshot = await query.get();
    _lastSyncTime = DateTime.now();
    return snapshot.docs.map(MarketPrice.fromFirestore).toList();
  }

  @override
  Future<List<MarketPrice>> syncDailyPrices() async {
    // Force a fresh server-side fetch by disabling the local cache for this call
    final snapshot = await _collection
        .orderBy('variety')
        .get(const GetOptions(source: Source.server));
    _lastSyncTime = DateTime.now();
    return snapshot.docs.map(MarketPrice.fromFirestore).toList();
  }

  @override
  Stream<List<MarketPrice>> watchMarketPrices() {
    return _collection.orderBy('variety').snapshots().map(
          (snapshot) =>
              snapshot.docs.map(MarketPrice.fromFirestore).toList(),
        );
  }
}
