import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/market_price.dart';
import '../../blocs/market_price/market_price_bloc.dart';

/// Inline widget that shows market price guidance for a specific coffee variety
/// when a farmer is creating or editing a listing.
///
/// - Displays the low / average / high prices for the selected [variety] and
///   [grade].
/// - Warns the farmer when [askingPrice] deviates more than 20 % from the
///   market average (Requirement 3.6, Property 14).
///
/// Requirements: 3.3, 3.6, 16.1 (Clean Architecture)
/// Developer: Developer 5
class PriceGuidanceWidget extends StatelessWidget {
  const PriceGuidanceWidget({
    super.key,
    required this.variety,
    required this.grade,
    this.askingPrice,
  });

  final String variety;
  final QualityGrade grade;
  final double? askingPrice;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketPriceBloc, MarketPriceState>(
      builder: (context, state) {
        if (state is MarketPriceInitial) {
          // Trigger load if not yet started
          context
              .read<MarketPriceBloc>()
              .add(const MarketPricesLoadRequested());
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.padding8),
            child: LinearProgressIndicator(),
          );
        }

        if (state is MarketPriceLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.padding8),
            child: LinearProgressIndicator(),
          );
        }

        if (state is MarketPricesLoaded) {
          final price = state.prices
              .where((p) =>
                  p.variety.toLowerCase() == variety.toLowerCase() &&
                  p.grade == grade)
              .firstOrNull;

          if (price == null) return const SizedBox.shrink();

          return _GuidanceCard(price: price, askingPrice: askingPrice);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.price, this.askingPrice});

  final MarketPrice price;
  final double? askingPrice;

  @override
  Widget build(BuildContext context) {
    final deviationWarning = _buildDeviationWarning();

    return Container(
      padding: const EdgeInsets.all(AppTheme.padding12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: AppTheme.borderRadiusMediumAll,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up,
                  size: AppTheme.iconSizeSmall, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.margin8),
              Text(
                'Market price – ${price.variety} (${_gradeLabel(price.grade)})',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.padding8),
          _PriceRow(price: price),
          if (deviationWarning != null) ...[
            const SizedBox(height: AppTheme.padding8),
            deviationWarning,
          ],
        ],
      ),
    );
  }

  Widget? _buildDeviationWarning() {
    final asking = askingPrice;
    if (asking == null || asking <= 0) return null;

    final avg = price.avgPrice;
    final deviation = ((asking - avg) / avg).abs();
    if (deviation <= 0.20) return null;

    final isTooHigh = asking > avg;
    return Row(
      children: [
        Icon(Icons.warning_amber_rounded,
            size: AppTheme.iconSizeSmall, color: AppTheme.warningColor),
        const SizedBox(width: AppTheme.margin8),
        Expanded(
          child: Text(
            isTooHigh
                ? 'Your asking price is ${(deviation * 100).toStringAsFixed(0)} % '
                    'above the market average. Buyers may negotiate down.'
                : 'Your asking price is ${(deviation * 100).toStringAsFixed(0)} % '
                    'below the market average. Consider reviewing your pricing.',
            style: AppTheme.caption.copyWith(color: AppTheme.warningColor),
          ),
        ),
      ],
    );
  }

  String _gradeLabel(QualityGrade g) =>
      g.name[0].toUpperCase() + g.name.substring(1);
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Col(label: 'Low', value: price.lowPrice, currency: price.currency),
        _Col(
            label: 'Avg',
            value: price.avgPrice,
            currency: price.currency,
            bold: true),
        _Col(label: 'High', value: price.highPrice, currency: price.currency),
      ],
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({
    required this.label,
    required this.value,
    required this.currency,
    this.bold = false,
  });

  final String label;
  final double value;
  final String currency;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.caption),
        Text(
          '$currency ${value.toStringAsFixed(2)}',
          style: AppTheme.caption.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
