import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../config/localization/app_localizations.dart';
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
      appBar: AppBar(
                elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context).appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: AppLocalizations.of(context).refresh,
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
            return LoadingIndicator(message: AppLocalizations.of(context).loadingDashboard);
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
    final loc = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ── Page header ─────────────────────────────────────────────
        Text(
          loc.myDashboard,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.buyerDashboardSubtitle,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 28),

        // ── Metric cards ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: loc.totalPurchases,
                value: dashboard.totalPurchases.toString(),
                onTap: () => Navigator.of(context).pushNamed('/transactions'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: loc.conversationsLabel,
                value: dashboard.conversations.toString(),
                onTap: () => Navigator.of(context).pushNamed('/messages'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: loc.savedLotsLabel,
          value: dashboard.savedListings.toString(),
          onTap: () => Navigator.of(context).pushNamed('/search'),
          fullWidth: true,
        ),
        const SizedBox(height: 28),

        // ── Quick actions ─────────────────────────────────────────────
        Text(
          loc.quickAccess,
          style: const TextStyle(
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
                label: loc.browseShop,
                onTap: () => Navigator.of(context).pushNamed('/search'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.show_chart,
                label: loc.marketPricesLabel,
                onTap: () =>
                    Navigator.of(context).pushNamed('/market-prices'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.chat_bubble_outline,
                label: loc.messages,
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
          color: Theme.of(context).colorScheme.surface,
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
          color: Theme.of(context).colorScheme.surface,
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
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
