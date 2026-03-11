import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../data/providers/market_price_provider.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/market_price.dart';

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
class PriceGuidanceWidget extends StatefulWidget {
  const PriceGuidanceWidget({
    super.key,
    required this.variety,
    required this.grade,
    this.askingPrice,
  });

  /// The coffee variety for which to show price guidance.
  final String variety;

  /// The quality grade; determines which price band to compare against.
  final QualityGrade grade;

  /// The farmer's asking price per kg. When provided and non-zero, a
  /// deviation warning may be shown.
  final double? askingPrice;

  @override
  State<PriceGuidanceWidget> createState() => _PriceGuidanceWidgetState();
}

class _PriceGuidanceWidgetState extends State<PriceGuidanceWidget> {
  MarketPrice? _price;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrice();
  }

  @override
  void didUpdateWidget(PriceGuidanceWidget old) {
    super.didUpdateWidget(old);
    if (old.variety != widget.variety || old.grade != widget.grade) {
      _fetchPrice();
    }
  }

  Future<void> _fetchPrice() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final provider =
        context.read<MarketPriceProvider>();
    final price =
        await provider.getPriceForVariety(widget.variety, widget.grade);
    if (!mounted) return;
    setState(() {
      _price = price;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.padding8),
        child: LinearProgressIndicator(),
      );
    }

    if (_price == null) {
      return const SizedBox.shrink();
    }

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
              const Icon(
                Icons.trending_up,
                size: AppTheme.iconSizeSmall,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.margin8),
              Text(
                'Market price – ${widget.variety} '
                '(${_gradeLabel(widget.grade)})',
                style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.padding8),
          _PriceRow(price: _price!),
          if (deviationWarning != null) ...[
            const SizedBox(height: AppTheme.padding8),
            deviationWarning,
          ],
        ],
      ),
    );
  }

  /// Returns a warning widget when the asking price deviates > 20 % from the
  /// market average (Requirement 3.6, Property 14).
  Widget? _buildDeviationWarning() {
    final asking = widget.askingPrice;
    if (asking == null || asking <= 0 || _price == null) return null;

    final avg = _price!.avgPrice;
    final deviation = ((asking - avg) / avg).abs();
    if (deviation <= 0.20) return null;

    final isTooHigh = asking > avg;
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: AppTheme.iconSizeSmall,
          color: AppTheme.warningColor,
        ),
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

  String _gradeLabel(QualityGrade grade) =>
      grade.name[0].toUpperCase() + grade.name.substring(1);
}

/// Compact row that displays the three price columns.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Column(
          label: 'Low',
          value: price.lowPrice,
          currency: price.currency,
        ),
        _Column(
          label: 'Avg',
          value: price.avgPrice,
          currency: price.currency,
          bold: true,
        ),
        _Column(
          label: 'High',
          value: price.highPrice,
          currency: price.currency,
        ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
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
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            color:
                bold ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
