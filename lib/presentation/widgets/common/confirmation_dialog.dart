import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import 'custom_button.dart';

/// Confirmation dialog type enumeration
enum ConfirmationDialogType {
  /// Default confirmation
  confirm,

  /// Warning confirmation (destructive action)
  warning,

  /// Danger confirmation (delete action)
  danger,

  /// Info dialog
  info,
}

/// Confirmation dialog widget following Clean Architecture principles
/// Requirements: 10.4, 10.5, 16.1
/// Developer: Developer 6
class ConfirmationDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog message/content
  final String message;

  /// Confirm button text
  final String confirmText;

  /// Cancel button text
  final String cancelText;

  /// Callback when confirmed
  final VoidCallback? onConfirm;

  /// Callback when cancelled
  final VoidCallback? onCancel;

  /// Dialog type
  final ConfirmationDialogType type;

  /// Custom icon
  final IconData? icon;

  /// Whether to show the icon
  final bool showIcon;

  /// Whether the dialog can be dismissed by tapping outside
  final bool barrierDismissible;

  /// Additional content widget
  final Widget? additionalContent;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.type = ConfirmationDialogType.confirm,
    this.icon,
    this.showIcon = true,
    this.barrierDismissible = true,
    this.additionalContent,
  });

  /// Show the confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    ConfirmationDialogType type = ConfirmationDialogType.confirm,
    IconData? icon,
    bool showIcon = true,
    bool barrierDismissible = true,
    Widget? additionalContent,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        type: type,
        icon: icon,
        showIcon: showIcon,
        barrierDismissible: barrierDismissible,
        additionalContent: additionalContent,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Show a delete confirmation dialog
  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
    String? additionalMessage,
  }) {
    return show(
      context: context,
      title: 'Delete $itemName?',
      message: additionalMessage ?? 'This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      type: ConfirmationDialogType.danger,
      icon: Icons.delete_outline,
    );
  }

  /// Show a discard changes confirmation dialog
  static Future<bool?> showDiscardChanges({required BuildContext context}) {
    return show(
      context: context,
      title: 'Discard changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmText: 'Discard',
      cancelText: 'Keep editing',
      type: ConfirmationDialogType.warning,
      icon: Icons.edit_off_outlined,
    );
  }

  /// Show a logout confirmation dialog
  static Future<bool?> showLogout({required BuildContext context}) {
    return show(
      context: context,
      title: 'Sign out?',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign out',
      cancelText: 'Cancel',
      type: ConfirmationDialogType.warning,
      icon: Icons.logout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLargeAll,
      ),
      contentPadding: const EdgeInsets.all(AppTheme.padding24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            _buildIcon(),
            const SizedBox(height: AppTheme.padding16),
          ],
          Text(title, style: AppTheme.heading2, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.padding12),
          Text(
            message,
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (additionalContent != null) ...[
            const SizedBox(height: AppTheme.padding16),
            additionalContent!,
          ],
          const SizedBox(height: AppTheme.padding24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final effectiveIcon = icon ?? _getDefaultIcon();
    final iconColor = _getIconColor();

    return Container(
      padding: const EdgeInsets.all(AppTheme.padding16),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        effectiveIcon,
        size: AppTheme.iconSizeLarge,
        color: iconColor,
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case ConfirmationDialogType.confirm:
        return Icons.help_outline;
      case ConfirmationDialogType.warning:
        return Icons.warning_amber_outlined;
      case ConfirmationDialogType.danger:
        return Icons.dangerous_outlined;
      case ConfirmationDialogType.info:
        return Icons.info_outline;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case ConfirmationDialogType.confirm:
        return AppTheme.primaryColor;
      case ConfirmationDialogType.warning:
        return AppTheme.warningColor;
      case ConfirmationDialogType.danger:
        return AppTheme.errorColor;
      case ConfirmationDialogType.info:
        return AppTheme.secondaryColor;
    }
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: cancelText,
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            type: ButtonType.outlined,
          ),
        ),
        const SizedBox(width: AppTheme.padding12),
        Expanded(
          child: CustomButton(
            text: confirmText,
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
            type: _getConfirmButtonType(),
          ),
        ),
      ],
    );
  }

  ButtonType _getConfirmButtonType() {
    switch (type) {
      case ConfirmationDialogType.confirm:
        return ButtonType.primary;
      case ConfirmationDialogType.warning:
        return ButtonType.primary;
      case ConfirmationDialogType.danger:
        return ButtonType.danger;
      case ConfirmationDialogType.info:
        return ButtonType.primary;
    }
  }
}

/// Info dialog for displaying information
class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData? icon;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.icon,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLargeAll,
      ),
      contentPadding: const EdgeInsets.all(AppTheme.padding24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.padding16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppTheme.iconSizeLarge,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.padding16),
          ],
          Text(title, style: AppTheme.heading2, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.padding12),
          Text(
            message,
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.padding24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: buttonText,
              onPressed: () => Navigator.of(context).pop(),
              type: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Input dialog for getting user input
class InputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hintText;
  final String confirmText;
  final String cancelText;
  final String? Function(String?)? validator;
  final int maxLines;

  const InputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hintText,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.validator,
    this.maxLines = 1,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? message,
    String? initialValue,
    String? hintText,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hintText: hintText,
        confirmText: confirmText,
        cancelText: cancelText,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() => _errorText = error);
        return;
      }
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusLargeAll,
      ),
      contentPadding: const EdgeInsets.all(AppTheme.padding24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTheme.heading2),
          if (widget.message != null) ...[
            const SizedBox(height: AppTheme.padding8),
            Text(
              widget.message!,
              style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: AppTheme.padding16),
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: AppTheme.borderRadiusMediumAll,
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: AppTheme.padding24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: widget.cancelText,
                  onPressed: () => Navigator.of(context).pop(),
                  type: ButtonType.outlined,
                ),
              ),
              const SizedBox(width: AppTheme.padding12),
              Expanded(
                child: CustomButton(
                  text: widget.confirmText,
                  onPressed: _onConfirm,
                  type: ButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
