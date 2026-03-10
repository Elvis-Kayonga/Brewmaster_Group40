// lib/domain/models/coffee_listing.dart

import 'enums.dart';

/// Coffee listing model representing a farmer's coffee for sale
/// Requirements: 2.1, 2.6, 8.4, 15.1, 16.1 (Clean Architecture)
/// Developer: Developer 2
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

  const CoffeeListing({
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
      listingId: json['listingId'] as String,
      farmerId: json['farmerId'] as String,
      variety: json['variety'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      pricePerKg: (json['pricePerKg'] as num).toDouble(),
      processingMethod: ProcessingMethodExtension.fromJson(
        json['processingMethod'] as String,
      ),
      altitude: (json['altitude'] as num).toDouble(),
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      qualityScore: (json['qualityScore'] as num).toDouble(),
      description: json['description'] as String,
      images: List<String>.from(json['images'] as List),
      location: json['location'] as String,
      status: ListingStatusExtension.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoffeeListing &&
        other.listingId == listingId &&
        other.farmerId == farmerId &&
        other.variety == variety &&
        other.quantity == quantity &&
        other.pricePerKg == pricePerKg &&
        other.processingMethod == processingMethod &&
        other.altitude == altitude &&
        other.harvestDate == harvestDate &&
        other.qualityScore == qualityScore &&
        other.description == description &&
        other.location == location &&
        other.status == status;
  }

  @override
  int get hashCode {
    return listingId.hashCode ^
        farmerId.hashCode ^
        variety.hashCode ^
        quantity.hashCode ^
        pricePerKg.hashCode ^
        processingMethod.hashCode ^
        altitude.hashCode ^
        harvestDate.hashCode ^
        qualityScore.hashCode ^
        description.hashCode ^
        location.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'CoffeeListing(listingId: $listingId, farmerId: $farmerId, variety: $variety, quantity: $quantity, pricePerKg: $pricePerKg, status: $status)';
  }
}
