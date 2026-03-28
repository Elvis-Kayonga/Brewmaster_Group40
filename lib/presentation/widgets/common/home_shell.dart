// lib/presentation/widgets/common/home_shell.dart
//
// Main app scaffold with bottom navigation bar.
// Buyers get: Shop, Sanctuary (saved), Orders, Messages, Profile
// Sellers get: My Store, Orders, Messages, Profile
//
// Requirements: 9.1, 9.2, 9.3, 10.1, 11.6
// Developer: Developer 6

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/localization/app_localizations.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/user_profile.dart';
import '../../blocs/messaging/notification_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../screens/dashboard/farmer_dashboard_screen.dart';
import '../../screens/dashboard/market_prices_screen.dart';
import '../../screens/messaging/conversations_screen.dart';
import '../../screens/payments/transaction_history_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';

/// Root scaffold rendered once the user is authenticated.
///
/// Manages a persistent [BottomNavigationBar] and keeps each tab alive via
/// [IndexedStack] so scroll positions and BLoC state are preserved across
/// tab switches.
class HomeShell extends StatefulWidget {
  final UserProfile profile;

  const HomeShell({super.key, required this.profile});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  /// Tracks which tab indices have been visited so screens are only built
  /// on first visit rather than all at once at startup.
  late final Set<int> _visitedIndices;

  /// Screen lists are cached so widget instances are not recreated on rebuild.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _visitedIndices = {0};
    _screens = widget.profile.role == UserRole.farmer
        ? [
            FarmerDashboardScreen(userId: widget.profile.id),
            TransactionHistoryScreen(userId: widget.profile.id, isFarmer: true),
            const MarketPricesScreen(),
            const ConversationsScreen(),
            const ProfileScreen(),
          ]
        : [
            const SearchScreen(),
            TransactionHistoryScreen(userId: widget.profile.id, isFarmer: false),
            const MarketPricesScreen(),
            const ConversationsScreen(),
            const ProfileScreen(),
          ];

    // Start the real-time profile watch immediately on login so ProfileBloc
    // always has fresh data (e.g. for ProfileAvatarButton photo updates).
    context.read<ProfileBloc>().add(ProfileWatchRequested(widget.profile.id));
    context.read<NotificationBloc>().add(NotificationsWatchRequested(widget.profile.id));
  }

  bool get _isFarmer => widget.profile.role == UserRole.farmer;

  List<BottomNavigationBarItem> _buyerNavItems(AppLocalizations loc) => [
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag_outlined),
          activeIcon: const Icon(Icons.shopping_bag),
          label: loc.shop,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_outlined),
          activeIcon: const Icon(Icons.receipt_long),
          label: loc.orders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart_outlined),
          activeIcon: const Icon(Icons.show_chart),
          label: loc.prices,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble_outline),
          activeIcon: const Icon(Icons.chat_bubble),
          label: loc.messages,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: loc.profile,
        ),
      ];

  List<BottomNavigationBarItem> _farmerNavItems(AppLocalizations loc) => [
        BottomNavigationBarItem(
          icon: const Icon(Icons.store_outlined),
          activeIcon: const Icon(Icons.store),
          label: loc.myStore,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_outlined),
          activeIcon: const Icon(Icons.receipt_long),
          label: loc.orders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart_outlined),
          activeIcon: const Icon(Icons.show_chart),
          label: loc.prices,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble_outline),
          activeIcon: const Icon(Icons.chat_bubble),
          label: loc.messages,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: loc.profile,
        ),
      ];

  void _onTabTapped(int index) {
    setState(() {
      _visitedIndices.add(index);
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final navItems = _isFarmer ? _farmerNavItems(loc) : _buyerNavItems(loc);

    // Clamp index to valid range if role changed
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _visitedIndices.add(0);
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: List.generate(_screens.length, (i) {
            // Only build a screen once it has been visited — avoids firing all
            // Firestore queries/streams simultaneously at startup.
            if (!_visitedIndices.contains(i)) return const SizedBox.shrink();
            return Offstage(
              offstage: i != safeIndex,
              child: _screens[i],
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: navItems,
        ),
      ),
    );
  }
}

