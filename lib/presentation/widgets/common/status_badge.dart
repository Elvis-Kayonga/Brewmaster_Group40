import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Status badge type enumeration
enum StatusBadgeType {
  /// Pending/waiting status
  pending,

  /// Active/in progress status
  active,

  /// Success/completed status
  success,

  /// Warning status
  warning,

  /// Error/failed status
  error,

  /// Info status
  info,

  /// Neutral/default status
  neutral,
}

/// Status badge size enumeration
enum StatusBadgeSize { small, medium, large }

/// Status badge widget following Clean Architecture principles
/// Requirements: 10.4, 10.5, 16.1
/// Developer: Developer 6
class StatusBadge extends StatelessWidget {
  /// Badge text/label
  final String label;

  /// Badge type determines color
  final StatusBadgeType type;

  /// Badge size
  final StatusBadgeSize size;

  /// Optional leading icon
  final IconData? icon;

  /// Whether to show a pulsing dot indicator
  final bool showIndicator;

  /// Custom background color override
  final Color? backgroundColor;

  /// Custom text color override
  final Color? textColor;

  /// Whether the badge is outlined (no fill)
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.size = StatusBadgeSize.medium,
    this.icon,
    this.showIndicator = false,
    this.backgroundColor,
    this.textColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(Theme.of(context).brightness);
    final bgColor = backgroundColor ?? colors.$1;
    final fgColor = textColor ?? colors.$2;

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor,
        border: outlined ? Border.all(color: fgColor, width: 1.5) : null,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIndicator) ...[
            _buildIndicator(fgColor),
            SizedBox(width: _getSpacing()),
          ],
          if (icon != null) ...[
            Icon(icon, size: _getIconSize(), color: fgColor),
            SizedBox(width: _getSpacing()),
          ],
          Text(label, style: _getTextStyle().copyWith(color: fgColor)),
        ],
      ),
    );
  }

  Widget _buildIndicator(Color color) {
    final indicatorSize = size == StatusBadgeSize.small ? 6.0 : 8.0;

    return Container(
      width: indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  (Color, Color) _getColors(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (type) {
      case StatusBadgeType.pending:
        return (
          isDark
              ? const Color(0xFFE65100).withValues(alpha: 0.2)
              : const Color(0xFFFFF3E0),
          isDark ? const Color(0xFFFF8A65) : const Color(0xFFE65100),
        );
      case StatusBadgeType.active:
        return (
          isDark
              ? const Color(0xFF1565C0).withValues(alpha: 0.2)
              : const Color(0xFFE3F2FD),
          isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
        );
      case StatusBadgeType.success:
        return (
          AppTheme.successColor.withValues(alpha: isDark ? 0.2 : 0.15),
          isDark ? const Color(0xFF81C784) : AppTheme.successColor,
        );
      case StatusBadgeType.warning:
        return (
          AppTheme.warningColor.withValues(alpha: isDark ? 0.2 : 0.15),
          isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17),
        );
      case StatusBadgeType.error:
        return (
          AppTheme.errorColor.withValues(alpha: isDark ? 0.2 : 0.15),
          isDark ? const Color(0xFFEF9A9A) : AppTheme.errorColor,
        );
      case StatusBadgeType.info:
        return (
          AppTheme.secondaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
          isDark ? const Color(0xFFA5D6A7) : AppTheme.secondaryColor,
        );
      case StatusBadgeType.neutral:
        return (
          isDark ? const Color(0xFF424242) : const Color(0xFFEEEEEE),
          isDark ? const Color(0xFF9E9E9E) : AppTheme.textSecondary,
        );
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case StatusBadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding8,
          vertical: AppTheme.padding4,
        );
      case StatusBadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding12,
          vertical: AppTheme.padding4 + 2,
        );
      case StatusBadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding16,
          vertical: AppTheme.padding8,
        );
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case StatusBadgeSize.small:
        return AppTheme.borderRadiusSmall;
      case StatusBadgeSize.medium:
        return AppTheme.borderRadiusMedium;
      case StatusBadgeSize.large:
        return AppTheme.borderRadiusMedium;
    }
  }

  double _getIconSize() {
    switch (size) {
      case StatusBadgeSize.small:
        return 12.0;
      case StatusBadgeSize.medium:
        return 14.0;
      case StatusBadgeSize.large:
        return 16.0;
    }
  }

  double _getSpacing() {
    switch (size) {
      case StatusBadgeSize.small:
        return 4.0;
      case StatusBadgeSize.medium:
        return 6.0;
      case StatusBadgeSize.large:
        return 8.0;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case StatusBadgeSize.small:
        return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
      case StatusBadgeSize.medium:
        return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
      case StatusBadgeSize.large:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    }
  }
}

/// Notification badge (count badge)
class NotificationBadge extends StatelessWidget {
  /// Count to display
  final int count;

  /// Maximum count to show before showing "+"
  final int maxCount;

  /// Badge color
  final Color? color;

  /// Text color
  final Color? textColor;

  /// Whether to show a dot instead of count
  final bool showDot;

  /// Badge size
  final double? size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.maxCount = 99,
    this.color,
    this.textColor,
    this.showDot = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showDot) {
      return const SizedBox.shrink();
    }

    final effectiveColor = color ?? AppTheme.errorColor;
    final effectiveTextColor = textColor ?? Colors.white;

    if (showDot) {
      return Container(
        width: size ?? 10,
        height: size ?? 10,
        decoration: BoxDecoration(
          color: effectiveColor,
          shape: BoxShape.circle,
        ),
      );
    }

    final displayText = count > maxCount ? '$maxCount+' : count.toString();
    final effectiveSize = size ?? 20.0;

    return Container(
      constraints: BoxConstraints(
        minWidth: effectiveSize,
        minHeight: effectiveSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(effectiveSize / 2),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Priority badge for task/item priority
class PriorityBadge extends StatelessWidget {
  /// Priority level (1 = highest, higher number = lower priority)
  final int priority;

  /// Custom labels for priority levels
  final Map<int, String>? labels;

  /// Badge size
  final StatusBadgeSize size;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.labels,
    this.size = StatusBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final label = labels?[priority] ?? _getDefaultLabel();
    final type = _getTypeForPriority();
    final icon = _getIconForPriority();

    return StatusBadge(label: label, type: type, size: size, icon: icon);
  }

  String _getDefaultLabel() {
    switch (priority) {
      case 1:
        return 'Critical';
      case 2:
        return 'High';
      case 3:
        return 'Medium';
      case 4:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  StatusBadgeType _getTypeForPriority() {
    switch (priority) {
      case 1:
        return StatusBadgeType.error;
      case 2:
        return StatusBadgeType.warning;
      case 3:
        return StatusBadgeType.info;
      case 4:
        return StatusBadgeType.neutral;
      default:
        return StatusBadgeType.neutral;
    }
  }

  IconData _getIconForPriority() {
    switch (priority) {
      case 1:
        return Icons.priority_high;
      case 2:
        return Icons.arrow_upward;
      case 3:
        return Icons.remove;
      case 4:
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }
}

/// Online status indicator
class OnlineStatusIndicator extends StatelessWidget {
  /// Whether the user is online
  final bool isOnline;

  /// Indicator size
  final double size;

  /// Whether to show a border
  final bool showBorder;

  const OnlineStatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 12.0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppTheme.successColor : AppTheme.textHint,
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: Theme.of(context).colorScheme.surface, width: 2) : null,
      ),
    );
  }
}

/// Tag/label badge
class TagBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TagBadge({
    super.key,
    required this.label,
    this.color,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding12,
          vertical: AppTheme.padding4,
        ),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close, size: 14, color: effectiveColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
