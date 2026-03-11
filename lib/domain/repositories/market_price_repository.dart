import '../models/market_price.dart';
import '../models/enums.dart';

/// Abstract interface for market price data operations.
///
/// Requirements: 3.1, 3.2, 3.4, 3.5
/// Developer: Developer 5
abstract class MarketPriceRepository {
  /// Returns all market price records (uses offline cache when unavailable).
  Future<List<MarketPrice>> getMarketPrices();

  /// Returns prices for a specific [variety], optionally filtered by [grade].
  Future<List<MarketPrice>> getPricesForVariety(
    String variety, {
    QualityGrade? grade,
  });

  /// Forces a fresh sync from the remote data source (Requirement 3.4).
  Future<List<MarketPrice>> syncDailyPrices();

  /// Real-time stream of all market prices.
  Stream<List<MarketPrice>> watchMarketPrices();

  /// Timestamp of the last successful sync; `null` before the first fetch.
  DateTime? get lastSyncTime;
}
