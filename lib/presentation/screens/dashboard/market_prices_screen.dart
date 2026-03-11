import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../data/providers/market_price_provider.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/market_price.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

/// Displays current market prices for all coffee varieties.
///
/// Shows price ranges (low / average / high) per quality grade, the last-sync
/// timestamp, and a refresh button.  When offline, Firestore's built-in
/// persistence serves cached data and the stale timestamp is shown
/// (Requirement 3.5, Property 13).
///
/// Requirements: 3.1, 3.2, 3.5, 16.1 (Clean Architecture)
/// Developer: Developer 5
class MarketPricesScreen extends StatefulWidget {
  const MarketPricesScreen({super.key});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  // Currently selected variety filter (null = show all)
  String? _selectedVariety;

  @override
  void initState() {
    super.initState();
    // Load prices on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketPriceProvider>().loadMarketPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync prices',
            onPressed: () =>
                context.read<MarketPriceProvider>().syncMarketPrices(),
          ),
        ],
      ),
      body: Consumer<MarketPriceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.hasPrices) {
            return const LoadingIndicator(
              message: 'Loading market prices…',
            );
          }

          if (provider.error != null && !provider.hasPrices) {
            return ErrorStateWidget(
              message: provider.error!,
              onRetry: provider.loadMarketPrices,
            );
          }

          final prices = _selectedVariety == null
              ? provider.prices
              : provider.prices
                  .where((p) => p.variety == _selectedVariety)
                  .toList();

          return Column(
            children: [
              // ── Sync timestamp banner ──────────────────────────────────
              if (provider.lastSyncTime != null)
                _SyncBanner(syncTime: provider.lastSyncTime!),

              // ── Variety filter chips ───────────────────────────────────
              if (provider.varieties.isNotEmpty)
                _VarietyFilterRow(
                  varieties: provider.varieties,
                  selected: _selectedVariety,
                  onSelected: (v) => setState(
                    () => _selectedVariety = _selectedVariety == v ? null : v,
                  ),
                ),

              // ── Price list ─────────────────────────────────────────────
              Expanded(
                child: prices.isEmpty
                    ? const Center(
                        child: Text(
                          'No market prices available.',
                          style: AppTheme.body,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.padding16),
                        itemCount: prices.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.margin8),
                        itemBuilder: (_, index) =>
                            _PriceCard(price: prices[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Banner showing when the price data was last synced (Requirement 3.5).
class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.syncTime});

  final DateTime syncTime;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM yyyy, HH:mm');
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding16,
        vertical: AppTheme.padding8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            size: AppTheme.iconSizeSmall,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: AppTheme.margin8),
          Text(
            'Last synced: ${formatter.format(syncTime)}',
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of filter chips for each variety.
class _VarietyFilterRow extends StatelessWidget {
  const _VarietyFilterRow({
    required this.varieties,
    required this.selected,
    required this.onSelected,
  });

  final List<String> varieties;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.padding16),
        scrollDirection: Axis.horizontal,
        itemCount: varieties.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppTheme.margin8),
        itemBuilder: (_, index) {
          final variety = varieties[index];
          final isSelected = selected == variety;
          return FilterChip(
            label: Text(variety),
            selected: isSelected,
            onSelected: (_) => onSelected(variety),
            selectedColor:
                AppTheme.primaryColor.withValues(alpha: 0.15),
            checkmarkColor: AppTheme.primaryColor,
            labelStyle: AppTheme.caption.copyWith(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textPrimary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

/// Card displaying the price range for one [MarketPrice] record.
class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLargeAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Variety + grade row
            Row(
              children: [
                const Icon(
                  Icons.local_cafe,
                  color: AppTheme.primaryColor,
                  size: AppTheme.iconSizeMedium,
                ),
                const SizedBox(width: AppTheme.margin8),
                Expanded(
                  child: Text(
                    price.variety,
                    style: AppTheme.heading2,
                  ),
                ),
                _GradeChip(grade: price.grade),
              ],
            ),
            const SizedBox(height: AppTheme.padding12),
            // Price range row
            _PriceRangeRow(
              low: price.lowPrice,
              avg: price.avgPrice,
              high: price.highPrice,
              currency: price.currency,
            ),
            const SizedBox(height: AppTheme.padding8),
            Text(
              'Updated: ${DateFormat('d MMM yyyy').format(price.updatedAt)}',
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small chip showing the quality grade.
class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.grade});

  final QualityGrade grade;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (grade) {
      case QualityGrade.specialty:
        color = AppTheme.successColor;
      case QualityGrade.premium:
        color = AppTheme.secondaryColor;
      case QualityGrade.standard:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding8,
        vertical: AppTheme.padding4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.borderRadiusRoundAll,
      ),
      child: Text(
        grade.name[0].toUpperCase() + grade.name.substring(1),
        style: AppTheme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Three-column price range row (low / average / high).
class _PriceRangeRow extends StatelessWidget {
  const _PriceRangeRow({
    required this.low,
    required this.avg,
    required this.high,
    required this.currency,
  });

  final double low;
  final double avg;
  final double high;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PriceColumn(
          label: 'Low',
          value: low,
          currency: currency,
          color: AppTheme.textSecondary,
        ),
        const Spacer(),
        _PriceColumn(
          label: 'Average',
          value: avg,
          currency: currency,
          color: AppTheme.primaryColor,
          isHighlighted: true,
        ),
        const Spacer(),
        _PriceColumn(
          label: 'High',
          value: high,
          currency: currency,
          color: AppTheme.successColor,
        ),
      ],
    );
  }
}

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    this.isHighlighted = false,
  });

  final String label;
  final double value;
  final String currency;
  final Color color;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTheme.caption),
        const SizedBox(height: 2),
        Text(
          '$currency ${value.toStringAsFixed(2)}/kg',
          style: isHighlighted
              ? AppTheme.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                )
              : AppTheme.body.copyWith(color: color),
        ),
      ],
    );
  }
}
