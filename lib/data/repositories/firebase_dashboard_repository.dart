import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/buyer_dashboard.dart';
import '../../domain/models/farmer_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Firebase implementation of [DashboardRepository].
///
/// Aggregates metrics from the [listings], [transactions], and [conversations]
/// Firestore collections. Firestore offline persistence keeps dashboards
/// readable without connectivity (Requirement 11.5).
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
/// Developer: Developer 5
class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Farmer dashboard
  // ---------------------------------------------------------------------------

  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    final results = await Future.wait([
      _firestore
          .collection('listings')
          .where('farmerId', isEqualTo: farmerId)
          .get(),
      _firestore
          .collection('transactions')
          .where('farmerId', isEqualTo: farmerId)
          .get(),
      _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: farmerId)
          .get(),
      _firestore.collection('users').get(),
    ]);

    final listingsSnap = results[0];
    final txSnap = results[1];
    final convoSnap = results[2];
    final usersSnap = results[3];

    final activeListings = listingsSnap.docs
        .where((d) => d.data()['status'] == 'active')
        .length;

    // Count how many buyers have saved any of this farmer's listings.
    final farmerListingIds = listingsSnap.docs.map((d) => d.id).toSet();
    final savedCount = usersSnap.docs.fold<int>(0, (acc, doc) {
      final saved =
          List<String>.from(doc.data()['savedListings'] as List? ?? []);
      return acc + saved.where(farmerListingIds.contains).length;
    });

    final completedTx =
        txSnap.docs.where((d) => d.data()['status'] == 'completed').toList();

    final totalEarnings = completedTx.fold<double>(
      0.0,
      (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // Current 30-day window
    final currentTx = completedTx.where((d) {
      final ts = d.data()['createdAt'];
      if (ts == null) return false;
      final date = (ts as Timestamp).toDate();
      return date.isAfter(thirtyDaysAgo);
    }).toList();

    final currentRevenue = currentTx.fold<double>(
      0.0,
      (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );
    final currentOrders = currentTx.length;

    // Previous 30-day window
    final prevTx = completedTx.where((d) {
      final ts = d.data()['createdAt'];
      if (ts == null) return false;
      final date = (ts as Timestamp).toDate();
      return date.isAfter(sixtyDaysAgo) && !date.isAfter(thirtyDaysAgo);
    }).toList();

    final prevRevenue = prevTx.fold<double>(
      0.0,
      (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );
    final prevOrders = prevTx.length;

    double? revenueChangePct;
    if (prevRevenue > 0) {
      revenueChangePct = ((currentRevenue - prevRevenue) / prevRevenue) * 100;
    } else if (currentRevenue > 0) {
      revenueChangePct = 100.0; // first sales this period
    }

    double? ordersChangePct;
    if (prevOrders > 0) {
      ordersChangePct =
          ((currentOrders - prevOrders) / prevOrders) * 100;
    } else if (currentOrders > 0) {
      ordersChangePct = 100.0;
    }

    // Daily revenue for the last 7 days (index 0 = 6 days ago, 6 = today)
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final dailyRevenue = List<double>.filled(7, 0.0);
    for (final d in completedTx) {
      final ts = d.data()['createdAt'];
      if (ts == null) continue;
      final date = (ts as Timestamp).toDate();
      if (date.isBefore(sevenDaysAgo)) continue;
      final dayIndex = date
          .difference(DateTime(sevenDaysAgo.year, sevenDaysAgo.month,
              sevenDaysAgo.day))
          .inDays
          .clamp(0, 6);
      dailyRevenue[dayIndex] +=
          (d.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    final totalConversations = convoSnap.docs.length;
    final responded = convoSnap.docs.where((d) {
      final unreadCount = (d.data()['unreadCount'] as num?)?.toInt() ?? 0;
      return unreadCount == 0;
    }).length;
    final responseRate = totalConversations == 0
        ? 0.0
        : (responded / totalConversations) * 100;

    return FarmerDashboard(
      activeListings: activeListings,
      totalEarnings: totalEarnings,
      conversations: totalConversations,
      savedCount: savedCount,
      responseRate: responseRate,
      revenueChangePct: revenueChangePct,
      ordersChangePct: ordersChangePct,
      dailyRevenue: dailyRevenue,
    );
  }

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) {
    return _firestore
        .collection('listings')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .asyncMap((_) => getFarmerDashboard(farmerId));
  }

  // ---------------------------------------------------------------------------
  // Buyer dashboard
  // ---------------------------------------------------------------------------

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) async {
    final results = await Future.wait([
      _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: buyerId)
          .get(),
      _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: buyerId)
          .get(),
      _firestore.collection('users').doc(buyerId).get(),
    ]);

    final txSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final convoSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final userDoc = results[2] as DocumentSnapshot<Map<String, dynamic>>;

    final totalPurchases = txSnap.docs
        .where((d) => d.data()['status'] == 'completed')
        .length;

    final conversations = convoSnap.docs.length;

    final savedListings =
        ((userDoc.data()?['savedListings'] as List?)?.length ?? 0);

    return BuyerDashboard(
      totalPurchases: totalPurchases,
      conversations: conversations,
      savedListings: savedListings,
    );
  }

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) {
    return _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .asyncMap((_) => getBuyerDashboard(buyerId));
  }
}
