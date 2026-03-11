import '../models/buyer_dashboard.dart';
import '../models/farmer_dashboard.dart';

/// Abstract interface for dashboard data operations.
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
/// Developer: Developer 5
abstract class DashboardRepository {
  /// Returns aggregated dashboard metrics for a farmer user.
  Future<FarmerDashboard> getFarmerDashboard(String farmerId);

  /// Returns aggregated dashboard metrics for a buyer user.
  Future<BuyerDashboard> getBuyerDashboard(String buyerId);

  /// Real-time stream of farmer dashboard metrics.
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId);

  /// Real-time stream of buyer dashboard metrics.
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId);
}
