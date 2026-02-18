// lib/domain/models/coffee_listing.dart

enum ProcessingMethod {
  washed,
  natural,
  honey,
}

enum ListingStatus {
  draft,
  active,
  sold,
  expired,
}

class CoffeeListing {
  final String listingId;
  final String farmerId;
  final String variety;
  final double quantity; // in KG
  final double pricePerKg;
  final ProcessingMethod processingMethod;
  final double altitude; // meters above sea level
  final DateTime harvestDate;
  final double qualityScore; // 0 - 100
  final String description;
  final List<String> images;
  final String location;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoffeeListing({
    required this.listingId,
    required this.farmerId,
    required this.variety,
    required this.quantity,
    required this.pricePerKg,
    required this.processingMethod,
    required this.altitude,
    required this.harvestDate,
    required this.qualityScore,
    required this.description,
    required this.images,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert object to JSON (for Firebase / API)
  Map<String, dynamic> toJson() {
    return {
      'listingId': listingId,
      'farmerId': farmerId,
      'variety': variety,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'processingMethod': processingMethod.name,
      'altitude': altitude,
      'harvestDate': harvestDate.toIso8601String(),
      'qualityScore': qualityScore,
      'description': description,
      'images': images,
      'location': location,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create object from JSON
  factory CoffeeListing.fromJson(Map<String, dynamic> json) {
    return CoffeeListing(
      listingId: json['listingId'],
      farmerId: json['farmerId'],
      variety: json['variety'],
      quantity: (json['quantity'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      processingMethod: ProcessingMethod.values.firstWhere(
        (e) => e.name == json['processingMethod'],
      ),
      altitude: (json['altitude'] as num).toDouble(),
      harvestDate: DateTime.parse(json['harvestDate']),
      qualityScore: (json['qualityScore'] as num).toDouble(),
      description: json['description'],
      images: List<String>.from(json['images']),
      location: json['location'],
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  CoffeeListing copyWith({
    String? listingId,
    String? farmerId,
    String? variety,
    double? quantity,
    double? pricePerKg,
    ProcessingMethod? processingMethod,
    double? altitude,
    DateTime? harvestDate,
    double? qualityScore,
    String? description,
    List<String>? images,
    String? location,
    ListingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoffeeListing(
      listingId: listingId ?? this.listingId,
      farmerId: farmerId ?? this.farmerId,
      variety: variety ?? this.variety,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      processingMethod: processingMethod ?? this.processingMethod,
      altitude: altitude ?? this.altitude,
      harvestDate: harvestDate ?? this.harvestDate,
      qualityScore: qualityScore ?? this.qualityScore,
      description: description ?? this.description,
      images: images ?? this.images,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
