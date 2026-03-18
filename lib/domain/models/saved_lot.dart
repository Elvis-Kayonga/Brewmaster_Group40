import 'package:equatable/equatable.dart';

/// A listing saved to a buyer's wishlist.
/// Snapshots key display fields so the screen renders without re-fetching
/// Firestore. Persisted under users/{userId}/savedLots/{listingId}.
class SavedLot extends Equatable {
  final String listingId;
  final String farmerId;
  final String? farmerName;
  final String variety;
  final double pricePerKg;
  final double availableQuantity;
  final String location;
  final String? imageUrl;
  final DateTime savedAt;

  const SavedLot({
    required this.listingId,
    required this.farmerId,
    this.farmerName,
    required this.variety,
    required this.pricePerKg,
    required this.availableQuantity,
    required this.location,
    this.imageUrl,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'variety': variety,
        'pricePerKg': pricePerKg,
        'availableQuantity': availableQuantity,
        'location': location,
        'imageUrl': imageUrl,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedLot.fromJson(Map<String, dynamic> json) => SavedLot(
        listingId: json['listingId'] as String,
        farmerId: json['farmerId'] as String,
        farmerName: json['farmerName'] as String?,
        variety: json['variety'] as String,
        pricePerKg: (json['pricePerKg'] as num).toDouble(),
        availableQuantity: (json['availableQuantity'] as num).toDouble(),
        location: json['location'] as String,
        imageUrl: json['imageUrl'] as String?,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );

  @override
  List<Object?> get props => [listingId];
}
