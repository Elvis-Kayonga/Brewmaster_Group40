import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'custom_button.dart';

/// Empty state widget following Clean Architecture principles
/// Requirements: 10.4, 10.5, 16.1
/// Developer: Developer 6
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Description text
  final String? description;

  /// Primary action button text
  final String? actionText;

  /// Callback for primary action
  final VoidCallback? onAction;

  /// Secondary action button text
  final String? secondaryActionText;

  /// Callback for secondary action
  final VoidCallback? onSecondaryAction;

  /// Custom icon color
  final Color? iconColor;

  /// Custom icon size
  final double? iconSize;

  /// Whether to use compact layout
  final bool compact;

  /// Custom image widget (overrides icon)
  final Widget? image;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.iconColor,
    this.iconSize,
    this.compact = false,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppTheme.padding16 : AppTheme.padding32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: compact ? AppTheme.padding12 : AppTheme.padding24),
            _buildTitle(),
            if (description != null) ...[
              SizedBox(height: compact ? AppTheme.padding8 : AppTheme.padding12),
              _buildDescription(),
            ],
            if (actionText != null || secondaryActionText != null) ...[
              SizedBox(height: compact ? AppTheme.padding16 : AppTheme.padding24),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (image != null) return image!;

    return Container(
      padding: EdgeInsets.all(compact ? AppTheme.padding12 : AppTheme.padding24),
      decoration: BoxDecoration(
        color: (iconColor ?? AppTheme.textSecondary).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize ?? (compact ? AppTheme.iconSizeLarge : AppTheme.iconSizeXLarge),
        color: iconColor ?? AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: compact ? AppTheme.heading2 : AppTheme.heading1,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      description!,
      style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions() {
    if (actionText != null && secondaryActionText != null) {
      return Column(
        children: [
          CustomButton(
            text: actionText!,
            onPressed: onAction,
            type: ButtonType.primary,
            isFullWidth: true,
          ),
          const SizedBox(height: AppTheme.padding12),
          CustomButton(
            text: secondaryActionText!,
            onPressed: onSecondaryAction,
            type: ButtonType.outlined,
            isFullWidth: true,
          ),
        ],
      );
    }

    if (actionText != null) {
      return CustomButton(
        text: actionText!,
        onPressed: onAction,
        type: ButtonType.primary,
      );
    }

    if (secondaryActionText != null) {
      return CustomButton(
        text: secondaryActionText!,
        onPressed: onSecondaryAction,
        type: ButtonType.outlined,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Specialized empty state for lists
class EmptyListState extends StatelessWidget {
  final String itemName;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyListState({
    super.key,
    required this.itemName,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.list_alt_outlined,
      title: 'No $itemName yet',
      description: 'When you add $itemName, they will appear here.',
      actionText: actionText ?? 'Add $itemName',
      onAction: onAction,
    );
  }
}

/// Specialized empty state for search results
class EmptySearchState extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const EmptySearchState({
    super.key,
    required this.query,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No results found',
      description: 'We couldn\'t find anything matching "$query".\nTry adjusting your search.',
      actionText: onClearSearch != null ? 'Clear search' : null,
      onAction: onClearSearch,
    );
  }
}

/// Specialized empty state for no internet connection
class NoConnectionState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'No connection',
      description: 'Please check your internet connection and try again.',
      actionText: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
    );
  }
}

/// Specialized empty state for no data/content
class NoDataState extends StatelessWidget {
  final String? title;
  final String? description;
  final IconData? icon;

  const NoDataState({
    super.key,
    this.title,
    this.description,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: icon ?? Icons.folder_open_outlined,
      title: title ?? 'No data available',
      description: description ?? 'There is no data to display at this time.',
    );
  }
}
