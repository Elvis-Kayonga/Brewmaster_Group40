// lib/presentation/widgets/common/home_shell.dart
//
// Main app scaffold with bottom navigation bar.
// Hosts the four primary destinations: Dashboard, Search, Messages, Profile.
// The correct dashboard variant (farmer/buyer) is selected from the
// authenticated UserProfile role.
//
// Requirements: 9.1, 9.2, 9.3, 10.1, 11.6
// Developer: Developer 6

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/localization/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/user_profile.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../screens/dashboard/buyer_dashboard_screen.dart';
import '../../screens/dashboard/farmer_dashboard_screen.dart';
import '../../screens/messaging/conversations_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/search/search_screen.dart';
import 'sync_status_indicator.dart';

/// Four primary navigation destinations.
enum _Tab { dashboard, search, messages, profile }

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
  _Tab _currentTab = _Tab.dashboard;

  void _onTabTapped(int index) {
    setState(() => _currentTab = _Tab.values[index]);
  }

  Widget _buildDashboard() {
    return widget.profile.role == UserRole.farmer
        ? FarmerDashboardScreen(userId: widget.profile.id)
        : BuyerDashboardScreen(userId: widget.profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final tabs = [
      _buildDashboard(),
      const SearchScreen(),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: loc.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: loc.search,
          ),
          BottomNavigationBarItem(
            icon: _MessagesTabIcon(profile: widget.profile),
            activeIcon: _MessagesTabIcon(profile: widget.profile, active: true),
            label: loc.messages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: loc.profile,
          ),
        ],
      ),
      // Connectivity indicator floats over all tabs.
      floatingActionButton: const SyncStatusIndicator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }
}

/// Messages tab icon; shows a badge when the user has unread notifications.
/// Currently renders a plain icon — badge support can be layered in via
/// NotificationBloc once the count is exposed.
class _MessagesTabIcon extends StatelessWidget {
  final UserProfile profile;
  final bool active;

  const _MessagesTabIcon({required this.profile, this.active = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Icon(
          active ? Icons.chat_bubble : Icons.chat_bubble_outline,
        );
      },
    );
  }
}
