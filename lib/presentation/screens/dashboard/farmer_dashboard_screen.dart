import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/farmer_dashboard.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

/// Dashboard screen for farmers.
///
/// Requirements: 11.1, 11.3, 11.4, 11.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key, required this.userId});

  final String userId;

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<DashboardBloc>()
        .add(FarmerDashboardLoadRequested(widget.userId));
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
            onPressed: () => context
                .read<DashboardBloc>()
                .add(FarmerDashboardLoadRequested(widget.userId)),
          ),
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
                  .add(FarmerDashboardLoadRequested(widget.userId)),
            );
          }
          if (state is FarmerDashboardLoaded) {
            return _FarmerDashboardBody(dashboard: state.dashboard);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _FarmerDashboardBody extends StatelessWidget {
  const _FarmerDashboardBody({required this.dashboard});

  final FarmerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.padding16),
      children: [
        _SectionHeader(title: 'Overview'),
        const SizedBox(height: AppTheme.margin8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.margin12,
          mainAxisSpacing: AppTheme.margin12,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(
              icon: Icons.list_alt,
              label: 'Active Listings',
              value: dashboard.activeListings.toString(),
              color: AppTheme.primaryColor,
            ),
            _MetricCard(
              icon: Icons.attach_money,
              label: 'Total Earnings',
              value: 'USD ${dashboard.totalEarnings.toStringAsFixed(2)}',
              color: AppTheme.successColor,
            ),
            _MetricCard(
              icon: Icons.chat_bubble_outline,
              label: 'Conversations',
              value: dashboard.conversations.toString(),
              color: AppTheme.secondaryColor,
            ),
            _MetricCard(
              icon: Icons.visibility_outlined,
              label: 'Total Views',
              value: dashboard.views.toString(),
              color: AppTheme.primaryDark,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.padding24),
        _SectionHeader(title: 'Response Rate'),
        const SizedBox(height: AppTheme.margin8),
        _ResponseRateCard(rate: dashboard.responseRate),
        const SizedBox(height: AppTheme.padding24),
        _SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppTheme.margin8),
        _QuickActionsRow(),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLargeAll),
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
                Text(value,
                    style: AppTheme.heading2.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label, style: AppTheme.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseRateCard extends StatelessWidget {
  const _ResponseRateCard({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    final badgeType = rate >= 80
        ? StatusBadgeType.success
        : rate >= 50
            ? StatusBadgeType.warning
            : StatusBadgeType.error;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLargeAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${rate.toStringAsFixed(0)} %', style: AppTheme.heading1),
                  const SizedBox(height: 4),
                  Text(
                    'You responded to ${rate.toStringAsFixed(0)} % of your conversations.',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.margin8),
            StatusBadge(
              label: rate >= 80
                  ? 'Excellent'
                  : rate >= 50
                      ? 'Good'
                      : 'Needs Attention',
              type: badgeType,
              icon: Icons.chat,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'New Listing',
            onTap: () => Navigator.of(context).pushNamed('/listings/new'),
          ),
        ),
        const SizedBox(width: AppTheme.margin12),
        Expanded(
          child: _ActionButton(
            icon: Icons.show_chart,
            label: 'Market Prices',
            onTap: () => Navigator.of(context).pushNamed('/market-prices'),
          ),
        ),
        const SizedBox(width: AppTheme.margin12),
        Expanded(
          child: _ActionButton(
            icon: Icons.message_outlined,
            label: 'Messages',
            onTap: () => Navigator.of(context).pushNamed('/messages'),
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
        padding: const EdgeInsets.symmetric(vertical: AppTheme.padding12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: AppTheme.borderRadiusLargeAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: AppTheme.iconSizeLarge),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: AppTheme.heading2.copyWith(color: AppTheme.primaryColor));
  }
}
