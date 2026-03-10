class SearchFilters {
  final String? variety;
  final String? method;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final double? minAltitude;
  final double? maxAltitude;

  const SearchFilters({
    this.variety,
    this.method,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.minAltitude,
    this.maxAltitude,
  });

  Map<String, dynamic> toJson() {
    return {
      if (variety != null) 'variety': variety,
      if (method != null) 'method': method,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (location != null) 'location': location,
      if (minAltitude != null) 'minAltitude': minAltitude,
      if (maxAltitude != null) 'maxAltitude': maxAltitude,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      variety: json['variety'] as String?,
      method: json['method'] as String?,
      minPrice: json['minPrice'] != null
          ? (json['minPrice'] as num).toDouble()
          : null,
      maxPrice: json['maxPrice'] != null
          ? (json['maxPrice'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      minAltitude: json['minAltitude'] != null
          ? (json['minAltitude'] as num).toDouble()
          : null,
      maxAltitude: json['maxAltitude'] != null
          ? (json['maxAltitude'] as num).toDouble()
          : null,
    );
  }

  SearchFilters copyWith({
    String? variety,
    String? method,
    double? minPrice,
    double? maxPrice,
    String? location,
    double? minAltitude,
    double? maxAltitude,
  }) {
    return SearchFilters(
      variety: variety ?? this.variety,
      method: method ?? this.method,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      minAltitude: minAltitude ?? this.minAltitude,
      maxAltitude: maxAltitude ?? this.maxAltitude,
    );
  }

  bool get hasActiveFilters {
    return variety != null ||
        method != null ||
        minPrice != null ||
        maxPrice != null ||
        location != null ||
        minAltitude != null ||
        maxAltitude != null;
  }

  SearchFilters clear() {
    return const SearchFilters();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchFilters &&
        other.variety == variety &&
        other.method == method &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.location == location &&
        other.minAltitude == minAltitude &&
        other.maxAltitude == maxAltitude;
  }

  @override
  int get hashCode {
    return variety.hashCode ^
        method.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        location.hashCode ^
        minAltitude.hashCode ^
        maxAltitude.hashCode;
  }

  @override
  String toString() {
    return 'SearchFilters(variety: $variety, method: $method, minPrice: $minPrice, maxPrice: $maxPrice, location: $location, minAltitude: $minAltitude, maxAltitude: $maxAltitude)';
  }
}
