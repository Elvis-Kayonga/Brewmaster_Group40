class FarmerDashboard {
  final int activeListings;
  final double totalEarnings;
  final int conversations;
  final int views;
  final double responseRate;

  const FarmerDashboard({
    required this.activeListings,
    required this.totalEarnings,
    required this.conversations,
    required this.views,
    required this.responseRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'activeListings': activeListings,
      'totalEarnings': totalEarnings,
      'conversations': conversations,
      'views': views,
      'responseRate': responseRate,
    };
  }

  factory FarmerDashboard.fromJson(Map<String, dynamic> json) {
    return FarmerDashboard(
      activeListings: json['activeListings'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      conversations: json['conversations'] as int,
      views: json['views'] as int,
      responseRate: (json['responseRate'] as num).toDouble(),
    );
  }

  factory FarmerDashboard.empty() {
    return const FarmerDashboard(
      activeListings: 0,
      totalEarnings: 0.0,
      conversations: 0,
      views: 0,
      responseRate: 0.0,
    );
  }

  FarmerDashboard copyWith({
    int? activeListings,
    double? totalEarnings,
    int? conversations,
    int? views,
    double? responseRate,
  }) {
    return FarmerDashboard(
      activeListings: activeListings ?? this.activeListings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      conversations: conversations ?? this.conversations,
      views: views ?? this.views,
      responseRate: responseRate ?? this.responseRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FarmerDashboard &&
        other.activeListings == activeListings &&
        other.totalEarnings == totalEarnings &&
        other.conversations == conversations &&
        other.views == views &&
        other.responseRate == responseRate;
  }

  @override
  int get hashCode {
    return activeListings.hashCode ^
        totalEarnings.hashCode ^
        conversations.hashCode ^
        views.hashCode ^
        responseRate.hashCode;
  }

  @override
  String toString() {
    return 'FarmerDashboard(activeListings: $activeListings, totalEarnings: $totalEarnings, conversations: $conversations, views: $views, responseRate: $responseRate)';
  }
}
