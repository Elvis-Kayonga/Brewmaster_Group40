import 'package:http/http.dart' as http;

import '../../domain/models/enums.dart';
import '../../domain/models/market_price.dart';

/// Fetches live coffee benchmark prices and maps them to app-specific
/// [MarketPrice] records.
class CoffeePriceApiService {
  CoffeePriceApiService({http.Client? client}) : _client = client ?? http.Client();

  // Stooq provides delayed commodity quotes without API keys.
  static final Uri _coffeeQuoteUri = Uri.parse('https://stooq.com/q/l/?s=kc.f&i=d');

  final http.Client _client;

  Future<List<MarketPrice>> fetchDailyPrices() async {
    final response = await _client.get(_coffeeQuoteUri).timeout(
      const Duration(seconds: 12),
    );
    if (response.statusCode != 200) {
      throw Exception('Coffee price API failed with status ${response.statusCode}.');
    }
    return _buildFromResponse(response.body);
  }

  List<MarketPrice> _buildFromResponse(String body) {
    final baseUsdPerKg = _parseUsdPerKg(body);
    final now = DateTime.now();
    return _buildTemplates(baseUsdPerKg)
        .map((t) => MarketPrice(
              id: _docIdFor(t.variety, t.grade),
              variety: t.variety,
              grade: t.grade,
              lowPrice: t.avgPrice * 0.9,
              avgPrice: t.avgPrice,
              highPrice: t.avgPrice * 1.1,
              currency: 'USD',
              updatedAt: now,
            ))
        .toList();
  }

  double _parseUsdPerKg(String csvBody) {
    // Stooq returns a single CSV line: SYMBOL,date,time,open,high,low,close,,
    // e.g. KC.F,20260325,171648,317.4,318.68,311.5,317.17,,
    final row = csvBody.trim().split(',');
    if (row.length < 7) {
      throw Exception('Coffee price API returned an unexpected format: $csvBody');
    }

    final closeCentsPerLb = double.tryParse(row[6]);
    if (closeCentsPerLb == null || closeCentsPerLb <= 0) {
      throw Exception('Coffee quote close value is invalid: ${row[6]}');
    }

    // KC futures are quoted in US cents/lb — convert to USD/kg.
    return (closeCentsPerLb / 100.0) * 2.20462262;
  }

  List<_PriceTemplate> _buildTemplates(double baseUsdPerKg) {
    return [
      _PriceTemplate(
        variety: 'Arabica',
        grade: QualityGrade.specialty,
        avgPrice: baseUsdPerKg * 1.2,
      ),
      _PriceTemplate(
        variety: 'Arabica',
        grade: QualityGrade.premium,
        avgPrice: baseUsdPerKg * 1.05,
      ),
      _PriceTemplate(
        variety: 'Arabica',
        grade: QualityGrade.standard,
        avgPrice: baseUsdPerKg * 0.95,
      ),
      _PriceTemplate(
        variety: 'Robusta',
        grade: QualityGrade.premium,
        avgPrice: baseUsdPerKg * 0.9,
      ),
      _PriceTemplate(
        variety: 'Bourbon',
        grade: QualityGrade.specialty,
        avgPrice: baseUsdPerKg * 1.15,
      ),
      _PriceTemplate(
        variety: 'SL28',
        grade: QualityGrade.specialty,
        avgPrice: baseUsdPerKg * 1.25,
      ),
    ];
  }

  String _docIdFor(String variety, QualityGrade grade) {
    final normalizedVariety = variety.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${normalizedVariety}_${grade.toJson()}';
  }
}

class _PriceTemplate {
  const _PriceTemplate({
    required this.variety,
    required this.grade,
    required this.avgPrice,
  });

  final String variety;
  final QualityGrade grade;
  final double avgPrice;
}