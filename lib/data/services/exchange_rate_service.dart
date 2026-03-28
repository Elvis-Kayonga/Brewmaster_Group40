import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches live USD exchange rates from frankfurter.app (free, no API key).
///
/// Used to convert USD listing prices to a buyer's local currency before
/// passing the charge amount to Flutterwave.
class ExchangeRateService {
  ExchangeRateService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // Cache rates for 10 minutes to avoid redundant network calls within a session.
  final Map<String, _CachedRate> _cache = {};

  /// Returns [usdAmount] converted to [targetCurrency].
  ///
  /// Falls back to the original USD amount (with code 'USD') if the network
  /// request fails or the target is already USD.
  Future<ConvertedAmount> convertFromUsd(
    double usdAmount,
    String targetCurrency,
  ) async {
    final code = targetCurrency.toUpperCase();
    if (code == 'USD' || code.isEmpty) {
      return ConvertedAmount(amount: usdAmount, currency: 'USD');
    }

    try {
      final rate = await _getRate(code);
      return ConvertedAmount(
        amount: double.parse((usdAmount * rate).toStringAsFixed(2)),
        currency: code,
      );
    } catch (_) {
      // Network error — fall back to USD so payment can still proceed.
      return ConvertedAmount(amount: usdAmount, currency: 'USD');
    }
  }

  Future<double> _getRate(String code) async {
    final cached = _cache[code];
    if (cached != null && !cached.isExpired) return cached.rate;

    // open.er-api.com: free, no API key, supports East African currencies
    // (KES, RWF, UGX, TZS, ETB, BIF) unlike frankfurter.app which only
    // covers ECB currencies.
    final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Exchange rate fetch failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['result'] != 'success') {
      throw Exception('Exchange rate API error: ${data['error-type']}');
    }
    final rates = data['rates'] as Map<String, dynamic>;
    if (!rates.containsKey(code)) {
      throw Exception('Currency $code not supported');
    }
    final rate = (rates[code] as num).toDouble();
    _cache[code] = _CachedRate(rate: rate);
    return rate;
  }
}

class ConvertedAmount {
  final double amount;
  final String currency;
  const ConvertedAmount({required this.amount, required this.currency});
}

class _CachedRate {
  final double rate;
  final DateTime _fetchedAt;

  _CachedRate({required this.rate}) : _fetchedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(_fetchedAt) > const Duration(minutes: 10);
}
