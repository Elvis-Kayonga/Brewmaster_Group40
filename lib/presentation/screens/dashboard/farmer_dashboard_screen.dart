import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/coffee_listing.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/escrow_transaction.dart';
import '../../../domain/models/farmer_dashboard.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/listing/listing_bloc.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/profile_avatar_button.dart';
import '../../widgets/listing/listing_card.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listing_form_screen.dart';
import '../payments/transaction_detail_screen.dart';

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
            return _FarmerDashboardBody(
                dashboard: state.dashboard, userId: widget.userId);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Dashboard body ─────────────────────────────────────────────────────────

class _FarmerDashboardBody extends StatefulWidget {
  const _FarmerDashboardBody(
      {required this.dashboard, required this.userId});

  final FarmerDashboard dashboard;
  final String userId;

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
        if (_selectedTab == 1) _OrdersTab(userId: widget.userId),
        if (_selectedTab == 2) _ListingsTab(farmerId: widget.userId),
      ],
    );
  }
}

// ── Analytics tab ──────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.dashboard});

  final FarmerDashboard dashboard;

  String? _formatChangePct(double? pct) {
    if (pct == null) return null;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _marketInsight(FarmerDashboard d) {
    final insights = <String>[];

    // Revenue trend
    if (d.revenueChangePct != null) {
      if (d.revenueChangePct! >= 20) {
        insights.add(
            'Revenue is up ${d.revenueChangePct!.toStringAsFixed(0)}% this month — strong momentum. Consider raising your price per kg on premium lots.');
      } else if (d.revenueChangePct! >= 5) {
        insights.add(
            'Revenue is trending upward. Keep your listings fresh and respond quickly to buyer enquiries to sustain growth.');
      } else if (d.revenueChangePct! < 0) {
        insights.add(
            'Revenue dipped ${d.revenueChangePct!.abs().toStringAsFixed(0)}% vs last month. Review your pricing and listing descriptions to stay competitive.');
      }
    }

    // Response rate
    if (d.responseRate >= 80) {
      insights.add(
          'Your response rate of ${d.responseRate.toStringAsFixed(0)}% is excellent — buyers are more likely to commit when replies are fast.');
    } else if (d.responseRate < 50 && d.conversations > 0) {
      insights.add(
          'Your response rate is ${d.responseRate.toStringAsFixed(0)}%. Replying to open conversations sooner can significantly improve conversion.');
    }

    // Active listings
    if (d.activeListings == 0) {
      insights.add(
          'You have no active listings. Add a lot to start receiving buyer enquiries.');
    } else if (d.activeListings < 3) {
      insights.add(
          'Adding more variety lots increases your visibility to buyers sourcing different origins and processing methods.');
    }

    // Views
    if (d.views == 0 && d.activeListings > 0) {
      insights.add(
          'Your listings haven\'t received views yet. Make sure your descriptions, altitude, and quality score are filled in — buyers filter by these.');
    }

    if (insights.isEmpty) {
      return 'Keep your listings active and respond promptly to buyer messages to build your reputation on the platform.';
    }
    return insights.join('\n\n');
  }

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
                change: _formatChangePct(dashboard.revenueChangePct),
                changePositive: (dashboard.revenueChangePct ?? 0) >= 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'ORDERS LOGGED',
                value: dashboard.conversations.toString(),
                change: _formatChangePct(dashboard.ordersChangePct),
                changePositive: (dashboard.ordersChangePct ?? 0) >= 0,
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
        // Velocity Command — 7-day revenue bar chart
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
              const SizedBox(height: 4),
              const Text(
                '7-day revenue',
                style: TextStyle(fontSize: 11, color: AppTheme.textHint),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: _RevenueBarChart(dailyRevenue: dashboard.dailyRevenue),
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
                    'Response rate: ${dashboard.responseRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Market Intelligence — dynamic advice
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
              Text(
                _marketInsight(dashboard),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.5,
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

class _OrdersTab extends StatefulWidget {
  const _OrdersTab({required this.userId});

  final String userId;

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentHistoryRequested(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      buildWhen: (_, curr) =>
          curr is PaymentInitial ||
          curr is PaymentLoading ||
          curr is PaymentHistoryLoaded,
      builder: (context, state) {
        if (state is PaymentInitial || state is PaymentLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transactions = state is PaymentHistoryLoaded
            ? state.transactions
                .where((t) => t.farmerId == widget.userId)
                .toList()
            : <Transaction>[];

        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No orders yet.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ),
          );
        }

        return Column(
          children: transactions.map((t) {
            final shortId =
                'ORD-${t.id.substring(0, 6).toUpperCase()}';
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(
                    transactionId: t.id,
                    userId: widget.userId,
                    isFarmer: true,
                  ),
                ),
              ),
              child: Container(
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
                            shortId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusLabel(t.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _statusColor(t.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${t.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppTheme.textSecondary),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Awaiting payment';
      case TransactionStatus.fundsHeld:
        return 'In escrow';
      case TransactionStatus.delivered:
        return 'Delivered — awaiting confirmation';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.disputed:
        return 'Under dispute';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.fundsHeld:
        return Colors.blue;
      case TransactionStatus.delivered:
        return Colors.teal;
      case TransactionStatus.completed:
        return const Color(0xFF388E3C);
      case TransactionStatus.disputed:
        return AppTheme.errorColor;
      case TransactionStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }
}

// ── Listings tab ───────────────────────────────────────────────────────────

class _ListingsTab extends StatefulWidget {
  const _ListingsTab({required this.farmerId});

  final String farmerId;

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab> {
  @override
  void initState() {
    super.initState();
    context
        .read<ListingBloc>()
        .add(FarmerListingsLoadRequested(widget.farmerId));
  }

  void _openCreate() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ListingBloc>(),
            child: ListingFormScreen(farmerId: widget.farmerId),
          ),
        ),
      );

  void _openDetail(CoffeeListing listing) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ListingBloc>(),
            child: ListingDetailScreen(listingId: listing.listingId),
          ),
        ),
      );

  void _openEdit(CoffeeListing listing) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<ListingBloc>(),
            child: ListingFormScreen(listing: listing),
          ),
        ),
      );

  void _confirmDelete(CoffeeListing listing) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Listing'),
          content:
              const Text('Are you sure you want to delete this listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<ListingBloc>()
                    .add(ListingDeleteRequested(listing.listingId));
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Create button ──────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openCreate,
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
        const SizedBox(height: 16),
        // ── Listings ───────────────────────────────────────────────
        BlocConsumer<ListingBloc, ListingState>(
          listener: (context, state) {
            if (state is ListingActionSuccess) {
              context
                  .read<ListingBloc>()
                  .add(FarmerListingsLoadRequested(widget.farmerId));
            }
          },
          builder: (context, state) {
            if (state is ListingLoading || state is ListingInitial) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final listings = state is FarmerListingsLoaded
                ? state.listings
                : const <CoffeeListing>[];
            if (listings.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No listings yet. Tap the button above to create your first lot.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              );
            }
            return Column(
              children: listings
                  .map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListingCard(
                          listing: l,
                          onTap: () => _openDetail(l),
                          onEdit: () => _openEdit(l),
                          onDelete: () => _confirmDelete(l),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
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

// ── Revenue bar chart ───────────────────────────────────────────────────────

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.dailyRevenue});

  final List<double> dailyRevenue;

  @override
  Widget build(BuildContext context) {
    final maxY = dailyRevenue.fold<double>(0, (m, v) => v > m ? v : m);
    final effectiveMax = maxY == 0 ? 10.0 : maxY * 1.2;

    return BarChart(
      BarChartData(
        maxY: effectiveMax,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: effectiveMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textHint.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final labels = ['6d', '5d', '4d', '3d', '2d', '1d', 'Today'];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textHint,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          final isToday = i == 6;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyRevenue[i],
                width: 14,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                color: isToday
                    ? AppTheme.primaryDark
                    : AppTheme.primaryColor.withValues(alpha: 0.55),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              rod.toY.toStringAsFixed(0),
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
