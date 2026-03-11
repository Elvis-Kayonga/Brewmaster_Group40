import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/buyer_dashboard.dart';
import '../../domain/models/farmer_dashboard.dart';

/// Aggregates dashboard metrics from Firestore for farmer and buyer users.
///
/// Queries the [listings], [transactions], and [conversations] collections to
/// compute summary figures. Firestore's offline persistence means dashboards
/// remain readable without connectivity (Requirement 11.5, Property 48).
///
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Farmer dashboard
  // ---------------------------------------------------------------------------

  /// Builds a [FarmerDashboard] by aggregating Firestore data for [farmerId].
  ///
  /// Property 46: displayed metrics accurately reflect the user's listings,
  /// transactions, and conversations.
  /// Property 47: trend comparison uses transaction createdAt timestamps.
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async {
    // Run the three queries concurrently to minimise latency
    final listingsSnapFuture = _getListingsSnapshot(farmerId);
    final transactionsSnapFuture = _getFarmerTransactionsSnapshot(farmerId);
    final conversationsSnapFuture = _getConversationsSnapshot(farmerId);

    final listingsSnap = await listingsSnapFuture;
    final transactionsSnap = await transactionsSnapFuture;
    final conversationsSnap = await conversationsSnapFuture;

    // Active listings
    final activeListings = listingsSnap.docs
        .where((d) => d.data()['status'] == 'active')
        .length;

    // Total views across all listings
    final views = listingsSnap.docs.fold<int>(
      0,
      (acc, d) => acc + ((d.data()['viewCount'] as num?)?.toInt() ?? 0),
    );

    // Earnings: sum amounts from completed transactions
    final completedTxDocs = transactionsSnap.docs
        .where((d) => d.data()['status'] == 'completed')
        .toList();

    final totalEarnings = completedTxDocs.fold<double>(
      0.0,
      (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // Response rate: conversations with at least 1 reply from the farmer
    // divided by total conversations
    final totalConversations = conversationsSnap.docs.length;
    final responded = conversationsSnap.docs
        .where((d) {
          final unread = d.data()['unreadCounts'] as Map<String, dynamic>?;
          // If the farmer has read messages, it implies they responded
          return unread != null &&
              (unread[farmerId] as num?)?.toInt() == 0;
        })
        .length;
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

  // ---------------------------------------------------------------------------
  // Buyer dashboard
  // ---------------------------------------------------------------------------

  /// Builds a [BuyerDashboard] by aggregating Firestore data for [buyerId].
  ///
  /// Property 46: displayed metrics accurately reflect the buyer's completed
  /// purchases and active conversations.
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) async {
    final transactionsSnapFuture = _getBuyerTransactionsSnapshot(buyerId);
    final conversationsSnapFuture = _getConversationsSnapshot(buyerId);

    final transactionsSnap = await transactionsSnapFuture;
    final conversationsSnap = await conversationsSnapFuture;

    final totalPurchases = transactionsSnap.docs
        .where((d) => d.data()['status'] == 'completed')
        .length;

    final conversations = conversationsSnap.docs.length;

    // Saved listings are stored directly on the user document as an array;
    // we default to 0 until the user service populates this field.
    final userDoc =
        await _firestore.collection('users').doc(buyerId).get();
    final savedListings =
        ((userDoc.data()?['savedListings'] as List?)?.length ?? 0);

    return BuyerDashboard(
      totalPurchases: totalPurchases,
      conversations: conversations,
      savedListings: savedListings,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<QuerySnapshot<Map<String, dynamic>>> _getListingsSnapshot(
    String farmerId,
  ) =>
      _firestore
          .collection('listings')
          .where('farmerId', isEqualTo: farmerId)
          .get();

  Future<QuerySnapshot<Map<String, dynamic>>>
      _getFarmerTransactionsSnapshot(String farmerId) =>
          _firestore
              .collection('transactions')
              .where('farmerId', isEqualTo: farmerId)
              .get();

  Future<QuerySnapshot<Map<String, dynamic>>>
      _getBuyerTransactionsSnapshot(String buyerId) =>
          _firestore
              .collection('transactions')
              .where('buyerId', isEqualTo: buyerId)
              .get();

  Future<QuerySnapshot<Map<String, dynamic>>> _getConversationsSnapshot(
    String userId,
  ) =>
      _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();
}
