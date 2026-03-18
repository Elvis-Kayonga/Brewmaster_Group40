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

import '../../../config/theme.dart';
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

  @override
  void initState() {
    super.initState();
    // Start the real-time profile watch immediately on login so ProfileBloc
    // always has fresh data (e.g. for ProfileAvatarButton photo updates).
    context
        .read<ProfileBloc>()
        .add(ProfileWatchRequested(widget.profile.id));
    context
        .read<NotificationBloc>()
        .add(NotificationsWatchRequested(widget.profile.id));
  }

  bool get _isFarmer => widget.profile.role == UserRole.farmer;

  List<Widget> get _buyerScreens => [
        const SearchScreen(),
        TransactionHistoryScreen(
          userId: widget.profile.id,
          isFarmer: false,
        ),
        const MarketPricesScreen(),
        const ConversationsScreen(),
        const ProfileScreen(),
      ];

  List<Widget> get _farmerScreens => [
        FarmerDashboardScreen(userId: widget.profile.id),
        TransactionHistoryScreen(
          userId: widget.profile.id,
          isFarmer: true,
        ),
        const MarketPricesScreen(),
        const ConversationsScreen(),
        const ProfileScreen(),
      ];

  List<BottomNavigationBarItem> get _buyerNavItems => const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_outlined),
          activeIcon: Icon(Icons.show_chart),
          label: 'Prices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

  List<BottomNavigationBarItem> get _farmerNavItems => const [
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'My Store',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_outlined),
          activeIcon: Icon(Icons.show_chart),
          label: 'Prices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = _isFarmer ? _farmerScreens : _buyerScreens;
    final navItems = _isFarmer ? _farmerNavItems : _buyerNavItems;

    // Clamp index to valid range if role changed
    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryDark,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        elevation: 8,
        items: navItems,
      ),
    );
  }
}

