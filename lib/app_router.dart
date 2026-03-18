// lib/app_router.dart
//
// Named-route generator for the BrewMaster app.
// All intra-app navigation uses these route names so deep links,
// integration tests, and analytics can address screens by name.
//
// Screens that require complex object arguments (ChatScreen, PaymentScreen)
// are intentionally excluded from named routes — callers push them with
// Navigator.push() and provide the full model objects directly.
//
// Requirements: 9.1, 9.2, 9.3, 9.5
// Developer: Developer 6

import 'package:flutter/material.dart';

import 'presentation/screens/dashboard/farmer_dashboard_screen.dart';
import 'presentation/screens/dashboard/buyer_dashboard_screen.dart';
import 'presentation/screens/dashboard/market_prices_screen.dart';
import 'presentation/screens/listings/listing_detail_screen.dart';
import 'presentation/screens/listings/listing_form_screen.dart';
import 'presentation/screens/listings/my_listings_screen.dart';
import 'presentation/screens/messaging/conversations_screen.dart';
import 'presentation/screens/payments/transaction_detail_screen.dart';
import 'presentation/screens/payments/transaction_history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/profile/verification_request_screen.dart';
import 'presentation/screens/search/search_screen.dart';

/// Canonical route names used throughout the app.
abstract class AppRoutes {
  // Dashboard
  static const farmerDashboard = '/dashboard/farmer';
  static const buyerDashboard = '/dashboard/buyer';
  static const marketPrices = '/market-prices';

  // Listings
  static const search = '/search';
  static const myListings = '/listings/mine';
  static const newListing = '/listings/new';
  static const listingDetail = '/listings/detail';

  // Messaging
  static const messages = '/messages';

  // Payments
  static const transactionHistory = '/transactions';
  static const transactionDetail = '/transactions/detail';

  // Profile
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const verification = '/profile/verification';

  // Notifications
  static const notifications = '/notifications';
}

/// Pass to [MaterialApp.onGenerateRoute].
///
/// Expected argument shapes per route:
/// - `farmerDashboard` / `buyerDashboard`: `{'userId': String}`
/// - `listingDetail`: `{'listingId': String}`
/// - `transactionDetail`: `{'transactionId': String, 'userId': String, 'isFarmer': bool}`
Route<dynamic>? generateRoute(RouteSettings settings) {
  final args =
      settings.arguments is Map<String, dynamic>
          ? settings.arguments as Map<String, dynamic>
          : <String, dynamic>{};

  switch (settings.name) {
    case AppRoutes.farmerDashboard:
      return _page(
          FarmerDashboardScreen(userId: args['userId'] as String? ?? ''));

    case AppRoutes.buyerDashboard:
      return _page(
          BuyerDashboardScreen(userId: args['userId'] as String? ?? ''));

    case AppRoutes.marketPrices:
      return _page(const MarketPricesScreen());

    case AppRoutes.search:
      return _page(const SearchScreen());

    case AppRoutes.myListings:
      return _page(
          MyListingsScreen(farmerId: args['farmerId'] as String? ?? ''));

    case AppRoutes.newListing:
      return _page(
          ListingFormScreen(farmerId: args['farmerId'] as String? ?? ''));

    case AppRoutes.listingDetail:
      return _page(
          ListingDetailScreen(listingId: args['listingId'] as String? ?? ''));

    case AppRoutes.messages:
      return _page(const ConversationsScreen());

    case AppRoutes.transactionHistory:
      return _page(TransactionHistoryScreen(
        userId: args['userId'] as String? ?? '',
        isFarmer: args['isFarmer'] as bool? ?? false,
      ));

    case AppRoutes.transactionDetail:
      return _page(TransactionDetailScreen(
        transactionId: args['transactionId'] as String? ?? '',
        userId: args['userId'] as String? ?? '',
        isFarmer: args['isFarmer'] as bool? ?? false,
      ));

    case AppRoutes.profile:
      return _page(const ProfileScreen());

    case AppRoutes.editProfile:
      // EditProfileScreen requires a UserProfile — push it imperatively.
      // Named route falls back to ProfileScreen.
      return _page(const ProfileScreen());

    case AppRoutes.verification:
      return _page(const VerificationRequestScreen());

    case AppRoutes.notifications:
      return _page(const NotificationsScreen());

    default:
      return null;
  }
}

MaterialPageRoute<T> _page<T>(Widget child) =>
    MaterialPageRoute<T>(builder: (_) => child);
