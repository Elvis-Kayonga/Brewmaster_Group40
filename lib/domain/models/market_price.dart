import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Market price model representing current prices for a coffee variety/grade.
/// Fields match the Firestore [marketPrices] collection exactly (ERD §6).
/// Requirements: 3.2, 16.1 (Clean Architecture)
/// Developer: Developer 5
class MarketPrice {
  /// Firestore document ID
  final String id;

  /// Coffee variety name (e.g. "Bourbon", "SL28")
  final String variety;

  /// Quality grade for this price band
  final QualityGrade grade;

  /// Low price per kg
  final double lowPrice;

  /// Average price per kg
  final double avgPrice;

  /// High price per kg
  final double highPrice;

  /// Currency code (e.g. "USD", "KES")
  final String currency;

  /// When this record was last updated
  final DateTime updatedAt;

  const MarketPrice({
    required this.id,
    required this.variety,
    required this.grade,
    required this.lowPrice,
    required this.avgPrice,
    required this.highPrice,
    required this.currency,
    required this.updatedAt,
  });

  /// Convert to Firestore JSON (field names match ERD exactly)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variety': variety,
      'grade': grade.toJson(),
      'lowPrice': lowPrice,
      'avgPrice': avgPrice,
      'highPrice': highPrice,
      'currency': currency,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore JSON map (handles both Timestamp and ISO string)
  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: json['id'] as String? ?? '',
      variety: json['variety'] as String,
      grade: QualityGradeExtension.fromJson(
        json['grade'] as String? ?? 'standard',
      ),
      lowPrice: (json['lowPrice'] as num).toDouble(),
      avgPrice: (json['avgPrice'] as num).toDouble(),
      highPrice: (json['highPrice'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convenience constructor from a Firestore [DocumentSnapshot]
  factory MarketPrice.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MarketPrice.fromJson({...doc.data()!, 'id': doc.id});
  }

  MarketPrice copyWith({
    String? id,
    String? variety,
    QualityGrade? grade,
    double? lowPrice,
    double? avgPrice,
    double? highPrice,
    String? currency,
    DateTime? updatedAt,
  }) {
    return MarketPrice(
      id: id ?? this.id,
      variety: variety ?? this.variety,
      grade: grade ?? this.grade,
      lowPrice: lowPrice ?? this.lowPrice,
      avgPrice: avgPrice ?? this.avgPrice,
      highPrice: highPrice ?? this.highPrice,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketPrice &&
        other.id == id &&
        other.variety == variety &&
        other.grade == grade &&
        other.lowPrice == lowPrice &&
        other.avgPrice == avgPrice &&
        other.highPrice == highPrice &&
        other.currency == currency &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      variety.hashCode ^
      grade.hashCode ^
      lowPrice.hashCode ^
      avgPrice.hashCode ^
      highPrice.hashCode ^
      currency.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'MarketPrice(id: $id, variety: $variety, grade: $grade, '
      'lowPrice: $lowPrice, avgPrice: $avgPrice, highPrice: $highPrice, '
      'currency: $currency, updatedAt: $updatedAt)';
}
