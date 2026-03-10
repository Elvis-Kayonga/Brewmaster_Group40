class MarketPrice {
  final String variety;
  final double lowPrice;
  final double avgPrice;
  final double highPrice;
  final DateTime date;

  const MarketPrice({
    required this.variety,
    required this.lowPrice,
    required this.avgPrice,
    required this.highPrice,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'variety': variety,
      'lowPrice': lowPrice,
      'avgPrice': avgPrice,
      'highPrice': highPrice,
      'date': date.toIso8601String(),
    };
  }

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      variety: json['variety'] as String,
      lowPrice: (json['lowPrice'] as num).toDouble(),
      avgPrice: (json['avgPrice'] as num).toDouble(),
      highPrice: (json['highPrice'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  MarketPrice copyWith({
    String? variety,
    double? lowPrice,
    double? avgPrice,
    double? highPrice,
    DateTime? date,
  }) {
    return MarketPrice(
      variety: variety ?? this.variety,
      lowPrice: lowPrice ?? this.lowPrice,
      avgPrice: avgPrice ?? this.avgPrice,
      highPrice: highPrice ?? this.highPrice,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MarketPrice &&
        other.variety == variety &&
        other.lowPrice == lowPrice &&
        other.avgPrice == avgPrice &&
        other.highPrice == highPrice &&
        other.date == date;
  }

  @override
  int get hashCode {
    return variety.hashCode ^
        lowPrice.hashCode ^
        avgPrice.hashCode ^
        highPrice.hashCode ^
        date.hashCode;
  }

  @override
  String toString() {
    return 'MarketPrice(variety: $variety, lowPrice: $lowPrice, avgPrice: $avgPrice, highPrice: $highPrice, date: $date)';
  }
}
