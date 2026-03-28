class FarmerDashboard {
  final int activeListings;
  final double totalEarnings;
  final int conversations;
  /// Total number of times buyers have saved any of this farmer's listings.
  final int savedCount;
  final double responseRate;
  /// Percentage change in revenue vs the previous 30-day window, e.g. 12.5
  final double? revenueChangePct;
  /// Percentage change in completed orders vs the previous 30-day window
  final double? ordersChangePct;
  /// Revenue per day for the last 7 days; index 0 = 6 days ago, index 6 = today
  final List<double> dailyRevenue;

  const FarmerDashboard({
    required this.activeListings,
    required this.totalEarnings,
    required this.conversations,
    required this.savedCount,
    required this.responseRate,
    this.revenueChangePct,
    this.ordersChangePct,
    this.dailyRevenue = const [0, 0, 0, 0, 0, 0, 0],
  });

  Map<String, dynamic> toJson() {
    return {
      'activeListings': activeListings,
      'totalEarnings': totalEarnings,
      'conversations': conversations,
      'savedCount': savedCount,
      'responseRate': responseRate,
    };
  }

  factory FarmerDashboard.fromJson(Map<String, dynamic> json) {
    return FarmerDashboard(
      activeListings: json['activeListings'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      conversations: json['conversations'] as int,
      savedCount: json['savedCount'] as int,
      responseRate: (json['responseRate'] as num).toDouble(),
    );
  }

  factory FarmerDashboard.empty() {
    return const FarmerDashboard(
      activeListings: 0,
      totalEarnings: 0.0,
      conversations: 0,
      savedCount: 0,
      responseRate: 0.0,
    );
  }

  FarmerDashboard copyWith({
    int? activeListings,
    double? totalEarnings,
    int? conversations,
    int? savedCount,
    double? responseRate,
    double? revenueChangePct,
    double? ordersChangePct,
    List<double>? dailyRevenue,
  }) {
    return FarmerDashboard(
      activeListings: activeListings ?? this.activeListings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      conversations: conversations ?? this.conversations,
      savedCount: savedCount ?? this.savedCount,
      responseRate: responseRate ?? this.responseRate,
      revenueChangePct: revenueChangePct ?? this.revenueChangePct,
      ordersChangePct: ordersChangePct ?? this.ordersChangePct,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FarmerDashboard &&
        other.activeListings == activeListings &&
        other.totalEarnings == totalEarnings &&
        other.conversations == conversations &&
        other.savedCount == savedCount &&
        other.responseRate == responseRate &&
        other.revenueChangePct == revenueChangePct &&
        other.ordersChangePct == ordersChangePct;
  }

  @override
  int get hashCode {
    return activeListings.hashCode ^
        totalEarnings.hashCode ^
        conversations.hashCode ^
        savedCount.hashCode ^
        responseRate.hashCode ^
        revenueChangePct.hashCode ^
        ordersChangePct.hashCode;
  }

  @override
  String toString() {
    return 'FarmerDashboard(activeListings: $activeListings, totalEarnings: $totalEarnings, conversations: $conversations, savedCount: $savedCount, responseRate: $responseRate, revenueChangePct: $revenueChangePct, ordersChangePct: $ordersChangePct, dailyRevenue: $dailyRevenue)';
  }
}
