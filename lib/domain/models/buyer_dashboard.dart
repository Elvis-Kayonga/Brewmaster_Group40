class BuyerDashboard {
  final int totalPurchases;
  final int conversations;
  final int savedListings;

  const BuyerDashboard({
    required this.totalPurchases,
    required this.conversations,
    required this.savedListings,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalPurchases': totalPurchases,
      'conversations': conversations,
      'savedListings': savedListings,
    };
  }

  factory BuyerDashboard.fromJson(Map<String, dynamic> json) {
    return BuyerDashboard(
      totalPurchases: json['totalPurchases'] as int,
      conversations: json['conversations'] as int,
      savedListings: json['savedListings'] as int,
    );
  }

  factory BuyerDashboard.empty() {
    return const BuyerDashboard(
      totalPurchases: 0,
      conversations: 0,
      savedListings: 0,
    );
  }

  BuyerDashboard copyWith({
    int? totalPurchases,
    int? conversations,
    int? savedListings,
  }) {
    return BuyerDashboard(
      totalPurchases: totalPurchases ?? this.totalPurchases,
      conversations: conversations ?? this.conversations,
      savedListings: savedListings ?? this.savedListings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BuyerDashboard &&
        other.totalPurchases == totalPurchases &&
        other.conversations == conversations &&
        other.savedListings == savedListings;
  }

  @override
  int get hashCode {
    return totalPurchases.hashCode ^
        conversations.hashCode ^
        savedListings.hashCode;
  }

  @override
  String toString() {
    return 'BuyerDashboard(totalPurchases: $totalPurchases, conversations: $conversations, savedListings: $savedListings)';
  }
}
