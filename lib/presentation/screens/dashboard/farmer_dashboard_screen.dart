import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/farmer_dashboard.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/profile_avatar_button.dart';

String _currencySymbol(String? country) {
  switch (country) {
    case 'Kenya':     return 'KSh';
    case 'Ethiopia':  return 'ETB';
    case 'Uganda':    return 'USh';
    case 'Tanzania':  return 'TSh';
    case 'Rwanda':    return 'RWF';
    case 'Burundi':   return 'BIF';
    default:          return 'USD';
  }
}

/// Dashboard screen for farmers — Farmer Command design.
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
            icon: const Icon(Icons.refresh, color: AppTheme.primaryDark),
            tooltip: 'Refresh',
            onPressed: () => context
                .read<DashboardBloc>()
                .add(FarmerDashboardLoadRequested(widget.userId)),
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

// ── Dashboard body ─────────────────────────────────────────────────────────

class _FarmerDashboardBody extends StatefulWidget {
  const _FarmerDashboardBody({required this.dashboard});

  final FarmerDashboard dashboard;

  @override
  State<_FarmerDashboardBody> createState() => _FarmerDashboardBodyState();
}

class _FarmerDashboardBodyState extends State<_FarmerDashboardBody> {
  int _selectedTab = 0; // 0 = ANALYTICS, 1 = ORDERS, 2 = LISTINGS

  static const _tabs = ['ANALYTICS', 'ORDERS', 'LISTINGS'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ── Page title ────────────────────────────────────────────────
        const Text(
          'Farmer\nCommand',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        // Seller status row
        Row(
          children: const [
            Icon(Icons.circle, size: 10, color: Color(0xFF4CAF50)),
            SizedBox(width: 6),
            Text(
              'Active Seller | Link: Secured',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ── Tab row ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = _selectedTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryDark
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        // ── Tab content ───────────────────────────────────────────────
        if (_selectedTab == 0) _AnalyticsTab(dashboard: widget.dashboard),
        if (_selectedTab == 1) _OrdersTab(dashboard: widget.dashboard),
        if (_selectedTab == 2) const _ListingsTab(),
      ],
    );
  }
}

// ── Analytics tab ──────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.dashboard});

  final FarmerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final country = authState is AuthAuthenticated
        ? authState.profile.country
        : null;
    final symbol = _currencySymbol(country);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric cards row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'TOTAL REVENUE',
                value: '$symbol ${dashboard.totalEarnings.toStringAsFixed(0)}',
                change: '+12%',
                changePositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'ORDERS LOGGED',
                value: dashboard.conversations.toString(),
                change: '+5%',
                changePositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'ACTIVE HUBS',
          value: dashboard.activeListings.toString(),
          wide: true,
        ),
        const SizedBox(height: 20),
        // Velocity Command chart placeholder
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VELOCITY COMMAND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.inputFillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Performance Chart',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textHint),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Views: ${dashboard.views}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Rate: ${dashboard.responseRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Market Intelligence card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MARKET INTELLIGENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your response rate is strong. Consider listing new specialty '
                'lots to capitalise on current buyer demand in origin hubs.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  'VIEW MARKET TRENDS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Orders tab ─────────────────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.dashboard});

  final FarmerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard.conversations == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No active orders at this time.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      children: List.generate(
        dashboard.conversations.clamp(0, 5),
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${(1000 + i).toString()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'In processing',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Listings tab ───────────────────────────────────────────────────────────

class _ListingsTab extends StatelessWidget {
  const _ListingsTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Listing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'List a new specialty coffee lot and connect with buyers directly.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/listings/new'),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                '+ INITIALIZE LOT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric card ────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool changePositive;
  final bool wide;

  const _MetricCard({
    required this.label,
    required this.value,
    this.change,
    this.changePositive = true,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: changePositive
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                        : AppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: changePositive
                          ? const Color(0xFF388E3C)
                          : AppTheme.errorColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
