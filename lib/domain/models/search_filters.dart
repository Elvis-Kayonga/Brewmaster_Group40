// lib/domain/models/search_filters.dart

class SearchFilters {
  final String? variety;
  final String? processingMethod;
  final double? minPrice;
  final double? maxPrice;
  final Map<String, double>? location;
  final double? minAltitude;
  final double? maxAltitude;

  SearchFilters({
    this.variety,
    this.processingMethod,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.minAltitude,
    this.maxAltitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'variety': variety,
      'processingMethod': processingMethod,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'location': location,
      'minAltitude': minAltitude,
      'maxAltitude': maxAltitude,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      variety: json['variety'] as String?,
      processingMethod: json['processingMethod'] as String?,
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      location: json['location'] != null ? Map<String, double>.from(json['location']) : null,
      minAltitude: json['minAltitude']?.toDouble(),
      maxAltitude: json['maxAltitude']?.toDouble(),
    );
  }

  SearchFilters copyWith({
    String? variety,
    String? processingMethod,
    double? minPrice,
    double? maxPrice,
    Map<String, double>? location,
    double? minAltitude,
    double? maxAltitude,
  }) {
    return SearchFilters(
      variety: variety ?? this.variety,
      processingMethod: processingMethod ?? this.processingMethod,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      minAltitude: minAltitude ?? this.minAltitude,
      maxAltitude: maxAltitude ?? this.maxAltitude,
    );
  }
}