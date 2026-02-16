import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'custom_button.dart';

/// Error state widget following Clean Architecture principles
/// Requirements: 10.4, 10.5, 16.1
/// Developer: Developer 6
class ErrorStateWidget extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Optional error title
  final String? title;

  /// Detailed error description
  final String? details;

  /// Custom icon
  final IconData icon;

  /// Custom icon color
  final Color? iconColor;

  /// Retry callback
  final VoidCallback? onRetry;

  /// Retry button text
  final String retryText;

  /// Secondary action text
  final String? secondaryActionText;

  /// Secondary action callback
  final VoidCallback? onSecondaryAction;

  /// Whether to use compact layout
  final bool compact;

  /// Whether to show error details in expandable section
  final bool showExpandableDetails;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.title,
    this.details,
    this.icon = Icons.error_outline,
    this.iconColor,
    this.onRetry,
    this.retryText = 'Try again',
    this.secondaryActionText,
    this.onSecondaryAction,
    this.compact = false,
    this.showExpandableDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          compact ? AppTheme.padding16 : AppTheme.padding32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: compact ? AppTheme.padding12 : AppTheme.padding24),
            if (title != null) ...[
              _buildTitle(),
              SizedBox(
                height: compact ? AppTheme.padding8 : AppTheme.padding12,
              ),
            ],
            _buildMessage(),
            if (details != null && showExpandableDetails) ...[
              const SizedBox(height: AppTheme.padding12),
              _buildExpandableDetails(context),
            ],
            if (onRetry != null || secondaryActionText != null) ...[
              SizedBox(
                height: compact ? AppTheme.padding16 : AppTheme.padding24,
              ),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final effectiveIconColor = iconColor ?? AppTheme.errorColor;

    return Container(
      padding: EdgeInsets.all(
        compact ? AppTheme.padding12 : AppTheme.padding24,
      ),
      decoration: BoxDecoration(
        color: effectiveIconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: compact ? AppTheme.iconSizeLarge : AppTheme.iconSizeXLarge,
        color: effectiveIconColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title!,
      style: (compact ? AppTheme.heading2 : AppTheme.heading1).copyWith(
        color: AppTheme.errorColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildExpandableDetails(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'Show details',
          style: AppTheme.caption.copyWith(color: AppTheme.primaryColor),
        ),
        tilePadding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.padding12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.05),
              borderRadius: AppTheme.borderRadiusMediumAll,
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              details!,
              style: AppTheme.caption.copyWith(
                fontFamily: 'monospace',
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final List<Widget> buttons = [];

    if (onRetry != null) {
      buttons.add(
        CustomButton(
          text: retryText,
          onPressed: onRetry,
          type: ButtonType.primary,
          leadingIcon: Icons.refresh,
        ),
      );
    }

    if (secondaryActionText != null && onSecondaryAction != null) {
      buttons.add(
        CustomButton(
          text: secondaryActionText!,
          onPressed: onSecondaryAction,
          type: ButtonType.outlined,
        ),
      );
    }

    if (buttons.length == 1) {
      return buttons.first;
    }

    return Column(
      children: buttons.map((button) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.padding8),
          child: button,
        );
      }).toList(),
    );
  }
}

/// Network error state
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool compact;

  const NetworkErrorWidget({super.key, this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Connection error',
      message:
          'Unable to connect to the server. Please check your internet connection.',
      icon: Icons.cloud_off_outlined,
      onRetry: onRetry,
      compact: compact,
    );
  }
}

/// Server error state
class ServerErrorWidget extends StatelessWidget {
  final String? errorCode;
  final VoidCallback? onRetry;
  final bool compact;

  const ServerErrorWidget({
    super.key,
    this.errorCode,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Server error',
      message: 'Something went wrong on our end. Please try again later.',
      details: errorCode != null ? 'Error code: $errorCode' : null,
      showExpandableDetails: errorCode != null,
      icon: Icons.dns_outlined,
      onRetry: onRetry,
      compact: compact,
    );
  }
}

/// Permission denied error state
class PermissionErrorWidget extends StatelessWidget {
  final String? permissionName;
  final VoidCallback? onRequestPermission;
  final bool compact;

  const PermissionErrorWidget({
    super.key,
    this.permissionName,
    this.onRequestPermission,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Permission required',
      message: permissionName != null
          ? '$permissionName access is required for this feature.'
          : 'Permission is required to access this feature.',
      icon: Icons.lock_outline,
      iconColor: AppTheme.warningColor,
      onRetry: onRequestPermission,
      retryText: 'Grant permission',
      compact: compact,
    );
  }
}

/// Authentication error state
class AuthErrorWidget extends StatelessWidget {
  final VoidCallback? onLogin;
  final bool compact;

  const AuthErrorWidget({super.key, this.onLogin, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Session expired',
      message: 'Your session has expired. Please sign in again to continue.',
      icon: Icons.login_outlined,
      iconColor: AppTheme.warningColor,
      onRetry: onLogin,
      retryText: 'Sign in',
      compact: compact,
    );
  }
}

/// Generic error banner for inline errors
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding16,
        vertical: AppTheme.padding12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: AppTheme.borderRadiusMediumAll,
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: AppTheme.iconSizeMedium,
          ),
          const SizedBox(width: AppTheme.padding12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body.copyWith(color: AppTheme.errorColor),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: AppTheme.errorColor,
              iconSize: AppTheme.iconSizeMedium,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppTheme.padding8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: AppTheme.errorColor,
              iconSize: AppTheme.iconSizeMedium,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
