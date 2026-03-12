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
    ]);

    final listingsSnap = results[0];
    final txSnap = results[1];
    final convoSnap = results[2];

    final activeListings = listingsSnap.docs
        .where((d) => d.data()['status'] == 'active')
        .length;

    final views = listingsSnap.docs.fold<int>(
      0,
      (acc, d) => acc + ((d.data()['viewCount'] as num?)?.toInt() ?? 0),
    );

    final totalEarnings = txSnap.docs
        .where((d) => d.data()['status'] == 'completed')
        .fold<double>(
          0.0,
          (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0.0),
        );

    final totalConversations = convoSnap.docs.length;
    final responded = convoSnap.docs.where((d) {
      final unread = d.data()['unreadCounts'] as Map<String, dynamic>?;
      return unread != null && (unread[farmerId] as num?)?.toInt() == 0;
    }).length;
    final responseRate = totalConversations == 0
        ? 0.0
        : (responded / totalConversations) * 100;

    return FarmerDashboard(
      activeListings: activeListings,
      totalEarnings: totalEarnings,
      conversations: totalConversations,
      views: views,
      responseRate: responseRate,
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
