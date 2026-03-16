import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/buyer_dashboard.dart';
import '../../widgets/common/profile_avatar_button.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

/// Dashboard screen for buyers — Figma design.
///
/// Requirements: 11.2, 11.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key, required this.userId});

  final String userId;

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<DashboardBloc>()
        .add(BuyerDashboardLoadRequested(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Brew Master',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryDark, size: 20),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DashboardBloc>()
                .add(BuyerDashboardLoadRequested(widget.userId)),
          ),
          const ProfileAvatarButton(),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const LoadingIndicator(message: 'Loading your dashboard…');
          }
          if (state is DashboardFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<DashboardBloc>()
                  .add(BuyerDashboardLoadRequested(widget.userId)),
            );
          }
          if (state is BuyerDashboardLoaded) {
            return _BuyerDashboardBody(dashboard: state.dashboard);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BuyerDashboardBody extends StatelessWidget {
  const _BuyerDashboardBody({required this.dashboard});

  final BuyerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ── Page header ─────────────────────────────────────────────
        const Text(
          'My\nDashboard',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your coffee purchasing activity at a glance.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 28),

        // ── Metric cards ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'TOTAL PURCHASES',
                value: dashboard.totalPurchases.toString(),
                onTap: () => Navigator.of(context).pushNamed('/transactions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'CONVERSATIONS',
                value: dashboard.conversations.toString(),
                onTap: () => Navigator.of(context).pushNamed('/messages'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'SAVED LOTS',
          value: dashboard.savedListings.toString(),
          onTap: () => Navigator.of(context).pushNamed('/search'),
          fullWidth: true,
        ),
        const SizedBox(height: 28),

        // ── Quick actions ─────────────────────────────────────────────
        const Text(
          'QUICK ACCESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.shopping_bag_outlined,
                label: 'Browse\nShop',
                onTap: () => Navigator.of(context).pushNamed('/search'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.show_chart,
                label: 'Market\nPrices',
                onTap: () =>
                    Navigator.of(context).pushNamed('/market-prices'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.chat_bubble_outline,
                label: 'Messages',
                onTap: () => Navigator.of(context).pushNamed('/messages'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
