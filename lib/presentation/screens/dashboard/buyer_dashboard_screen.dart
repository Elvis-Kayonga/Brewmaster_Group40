import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../domain/models/buyer_dashboard.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

/// Dashboard screen for buyers.
///
/// Displays key metrics: total completed purchases, active conversations,
/// and saved listings.  Tapping a metric navigates to the corresponding
/// detail screen (Requirement 11.6).
///
/// Requirements: 11.2, 11.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({
    super.key,
    required this.userId,
  });

  /// The Firebase Auth UID of the logged-in buyer.
  final String userId;

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DashboardProvider>()
          .loadDashboard(widget.userId, UserRole.buyer);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<DashboardProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingIndicator(
              message: 'Loading your dashboard…',
            );
          }

          if (provider.error != null) {
            return ErrorStateWidget(
              message: provider.error!,
              onRetry: provider.refresh,
            );
          }

          return _BuyerDashboardBody(
            dashboard: provider.buyerDashboard,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard body
// ─────────────────────────────────────────────────────────────────────────────

class _BuyerDashboardBody extends StatelessWidget {
  const _BuyerDashboardBody({required this.dashboard});

  final BuyerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.padding16),
        children: [
          // ── Overview ─────────────────────────────────────────────
          _SectionHeader(title: 'Overview'),
          const SizedBox(height: AppTheme.margin8),

          // ── Metric cards ─────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.margin12,
            mainAxisSpacing: AppTheme.margin12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Total Purchases',
                value: dashboard.totalPurchases.toString(),
                color: AppTheme.primaryColor,
                onTap: () => Navigator.of(context)
                    .pushNamed('/transactions'),
              ),
              _MetricCard(
                icon: Icons.chat_bubble_outline,
                label: 'Conversations',
                value: dashboard.conversations.toString(),
                color: AppTheme.secondaryColor,
                onTap: () => Navigator.of(context)
                    .pushNamed('/messages'),
              ),
              _MetricCard(
                icon: Icons.bookmark_outline,
                label: 'Saved Listings',
                value: dashboard.savedListings.toString(),
                color: AppTheme.primaryDark,
                onTap: () => Navigator.of(context)
                    .pushNamed('/search'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.padding24),

          // ── Quick actions ─────────────────────────────────────────
          _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: AppTheme.margin8),
          _QuickActionsRow(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric card
// ─────────────────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLargeAll,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusLargeAll,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: AppTheme.iconSizeLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTheme.heading2.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: AppTheme.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions row
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.search,
            label: 'Browse Listings',
            onTap: () =>
                Navigator.of(context).pushNamed('/search'),
          ),
        ),
        const SizedBox(width: AppTheme.margin12),
        Expanded(
          child: _ActionButton(
            icon: Icons.show_chart,
            label: 'Market Prices',
            onTap: () =>
                Navigator.of(context).pushNamed('/market-prices'),
          ),
        ),
        const SizedBox(width: AppTheme.margin12),
        Expanded(
          child: _ActionButton(
            icon: Icons.message_outlined,
            label: 'Messages',
            onTap: () =>
                Navigator.of(context).pushNamed('/messages'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.borderRadiusLargeAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.padding12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: AppTheme.borderRadiusLargeAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: AppTheme.iconSizeLarge,
            ),
            const SizedBox(height: AppTheme.margin4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.heading2.copyWith(color: AppTheme.primaryColor),
    );
  }
}
