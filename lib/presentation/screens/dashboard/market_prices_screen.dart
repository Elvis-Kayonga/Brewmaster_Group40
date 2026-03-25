import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/market_price.dart';
import '../../blocs/market_price/market_price_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/profile_avatar_button.dart';

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
  String? _selectedVariety;

  @override
  void initState() {
    super.initState();
    // Sync on load so Firestore is always populated from the Stooq API.
    context.read<MarketPriceBloc>().add(const MarketPricesSyncRequested());
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
            tooltip: 'Sync prices',
            onPressed: () => context
                .read<MarketPriceBloc>()
                .add(const MarketPricesSyncRequested()),
          ),
          const ProfileAvatarButton(),
        ],
      ),
      body: BlocBuilder<MarketPriceBloc, MarketPriceState>(
        builder: (context, state) {
          if (state is MarketPriceLoading || state is MarketPriceInitial) {
            return const LoadingIndicator(message: 'Loading market prices…');
          }

          if (state is MarketPriceFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context
                  .read<MarketPriceBloc>()
                  .add(const MarketPricesSyncRequested()),
            );
          }

          if (state is MarketPricesLoaded) {
            final allPrices = state.prices;
            final varieties =
                allPrices.map((p) => p.variety).toSet().toList()..sort();

            final prices = _selectedVariety == null
                ? allPrices
                : allPrices
                    .where((p) => p.variety == _selectedVariety)
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market\nPrices',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'LIVE COMMODITY INDEX',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (varieties.isNotEmpty)
                  _VarietyFilterRow(
                    varieties: varieties,
                    selected: _selectedVariety,
                    onSelected: (v) => setState(
                      () =>
                          _selectedVariety = _selectedVariety == v ? null : v,
                    ),
                  ),
                Expanded(
                  child: prices.isEmpty
                      ? const Center(
                          child: Text(
                            'No market prices available.',
                            style: AppTheme.body,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: prices.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppTheme.margin8),
                          itemBuilder: (_, index) =>
                              _PriceCard(price: prices[index]),
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding16),
        scrollDirection: Axis.horizontal,
        itemCount: varieties.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.margin8),
        itemBuilder: (_, index) {
          final variety = varieties[index];
          final isSelected = selected == variety;
          return FilterChip(
            label: Text(variety),
            selected: isSelected,
            onSelected: (_) => onSelected(variety),
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            checkmarkColor: AppTheme.primaryColor,
            labelStyle: AppTheme.caption.copyWith(
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLargeAll),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_cafe,
                    color: AppTheme.primaryColor,
                    size: AppTheme.iconSizeMedium),
                const SizedBox(width: AppTheme.margin8),
                Expanded(child: Text(price.variety, style: AppTheme.heading2)),
                _GradeChip(grade: price.grade),
              ],
            ),
            const SizedBox(height: AppTheme.padding12),
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
          horizontal: AppTheme.padding8, vertical: AppTheme.padding4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.borderRadiusRoundAll,
      ),
      child: Text(
        grade.name[0].toUpperCase() + grade.name.substring(1),
        style: AppTheme.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

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
            color: AppTheme.textSecondary),
        const Spacer(),
        _PriceColumn(
            label: 'Average',
            value: avg,
            currency: currency,
            color: AppTheme.primaryColor,
            isHighlighted: true),
        const Spacer(),
        _PriceColumn(
            label: 'High',
            value: high,
            currency: currency,
            color: AppTheme.successColor),
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
              ? AppTheme.body.copyWith(color: color, fontWeight: FontWeight.bold)
              : AppTheme.body.copyWith(color: color),
        ),
      ],
    );
  }
}
