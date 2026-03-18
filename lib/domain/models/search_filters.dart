class SearchFilters {
  final String? query;
  final String? method;
  final String? country;
  final double? minPrice;
  final double? maxPrice;
  final double? minAltitude;
  final double? maxAltitude;

  const SearchFilters({
    this.query,
    this.method,
    this.country,
    this.minPrice,
    this.maxPrice,
    this.minAltitude,
    this.maxAltitude,
  });

  Map<String, dynamic> toJson() {
    return {
      if (query != null) 'query': query,
      if (method != null) 'method': method,
      if (country != null) 'country': country,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minAltitude != null) 'minAltitude': minAltitude,
      if (maxAltitude != null) 'maxAltitude': maxAltitude,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      query: json['query'] as String?,
      method: json['method'] as String?,
      country: json['country'] as String?,
      minPrice: json['minPrice'] != null
          ? (json['minPrice'] as num).toDouble()
          : null,
      maxPrice: json['maxPrice'] != null
          ? (json['maxPrice'] as num).toDouble()
          : null,
      minAltitude: json['minAltitude'] != null
          ? (json['minAltitude'] as num).toDouble()
          : null,
      maxAltitude: json['maxAltitude'] != null
          ? (json['maxAltitude'] as num).toDouble()
          : null,
    );
  }

  SearchFilters copyWith({
    String? query,
    String? method,
    String? country,
    double? minPrice,
    double? maxPrice,
    double? minAltitude,
    double? maxAltitude,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      method: method ?? this.method,
      country: country ?? this.country,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minAltitude: minAltitude ?? this.minAltitude,
      maxAltitude: maxAltitude ?? this.maxAltitude,
    );
  }

  bool get hasActiveFilters {
    return query != null ||
        method != null ||
        country != null ||
        minPrice != null ||
        maxPrice != null ||
        minAltitude != null ||
        maxAltitude != null;
  }

  SearchFilters clear() => const SearchFilters();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
        other.query == query &&
        other.method == method &&
        other.country == country &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minAltitude == minAltitude &&
        other.maxAltitude == maxAltitude;
  }

  @override
  int get hashCode {
    return query.hashCode ^
        method.hashCode ^
        country.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        minAltitude.hashCode ^
        maxAltitude.hashCode;
  }

  @override
  String toString() {
    return 'SearchFilters(query: $query, method: $method, country: $country, minPrice: $minPrice, maxPrice: $maxPrice, minAltitude: $minAltitude, maxAltitude: $maxAltitude)';
  }
}
