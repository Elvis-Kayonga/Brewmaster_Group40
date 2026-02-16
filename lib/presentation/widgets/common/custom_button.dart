import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Button type enumeration
enum ButtonType {
  primary,
  secondary,
  outlined,
  text,
  danger,
  success,
}

/// Button size enumeration
enum ButtonSize {
  small,
  medium,
  large,
}

/// Custom Button widget following Clean Architecture principles
/// Requirements: 1.5, 10.2, 16.1
/// CRITICAL - Shared component used by all developers
class CustomButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button type (primary, secondary, outlined, text, danger, success)
  final ButtonType type;

  /// Button size (small, medium, large)
  final ButtonSize size;

  /// Leading icon
  final IconData? leadingIcon;

  /// Trailing icon
  final IconData? trailingIcon;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Whether the button should expand to full width
  final bool isFullWidth;

  /// Whether the button is disabled
  final bool isDisabled;

  /// Custom background color override
  final Color? backgroundColor;

  /// Custom text color override
  final Color? textColor;

  /// Custom border radius override
  final double? borderRadius;

  /// Custom padding override
  final EdgeInsetsGeometry? padding;

  /// Custom elevation
  final double? elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;

    Widget buttonChild = _buildButtonContent();

    if (isFullWidth) {
      buttonChild = SizedBox(
        width: double.infinity,
        child: _buildButton(buttonStyle, effectiveOnPressed, buttonChild),
      );
    } else {
      buttonChild = _buildButton(buttonStyle, effectiveOnPressed, buttonChild);
    }

    return buttonChild;
  }

  Widget _buildButton(
    ButtonStyle style,
    VoidCallback? onPressed,
    Widget child,
  ) {
    switch (type) {
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      case ButtonType.text:
        return TextButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
      default:
        return ElevatedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
        ),
      );
    }

    final List<Widget> children = [];

    if (leadingIcon != null) {
      children.add(
        Icon(
          leadingIcon,
          size: _getIconSize(),
          color: _getContentColor(),
        ),
      );
      children.add(SizedBox(width: _getIconSpacing()));
    }

    children.add(
      Text(
        text,
        style: _getTextStyle(),
      ),
    );

    if (trailingIcon != null) {
      children.add(SizedBox(width: _getIconSpacing()));
      children.add(
        Icon(
          trailingIcon,
          size: _getIconSize(),
          color: _getContentColor(),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  ButtonStyle _getButtonStyle() {
    final effectiveBorderRadius = borderRadius ?? AppTheme.borderRadiusMedium;
    final effectivePadding = padding ?? _getDefaultPadding();

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: textColor ?? AppTheme.onPrimaryColor,
          padding: effectivePadding,
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          disabledForegroundColor: AppTheme.onPrimaryColor.withOpacity(0.7),
        );

      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.secondaryColor,
          foregroundColor: textColor ?? AppTheme.onSecondaryColor,
          padding: effectivePadding,
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          disabledBackgroundColor: AppTheme.secondaryColor.withOpacity(0.5),
          disabledForegroundColor: AppTheme.onSecondaryColor.withOpacity(0.7),
        );

      case ButtonType.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppTheme.primaryColor,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          side: BorderSide(
            color: backgroundColor ?? AppTheme.primaryColor,
            width: 1.5,
          ),
          disabledForegroundColor: AppTheme.primaryColor.withOpacity(0.5),
        );

      case ButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: textColor ?? AppTheme.primaryColor,
          padding: effectivePadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          disabledForegroundColor: AppTheme.primaryColor.withOpacity(0.5),
        );

      case ButtonType.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.errorColor,
          foregroundColor: textColor ?? AppTheme.onErrorColor,
          padding: effectivePadding,
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          disabledBackgroundColor: AppTheme.errorColor.withOpacity(0.5),
          disabledForegroundColor: AppTheme.onErrorColor.withOpacity(0.7),
        );

      case ButtonType.success:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.successColor,
          foregroundColor: textColor ?? Colors.white,
          padding: effectivePadding,
          elevation: elevation ?? 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
          ),
          disabledBackgroundColor: AppTheme.successColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
        );
    }
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding12,
          vertical: AppTheme.padding8,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding24,
          vertical: AppTheme.padding12,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.padding32,
          vertical: AppTheme.padding16,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppTheme.iconSizeSmall;
      case ButtonSize.medium:
        return AppTheme.iconSizeMedium - 4;
      case ButtonSize.large:
        return AppTheme.iconSizeMedium;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case ButtonSize.small:
        return AppTheme.padding4;
      case ButtonSize.medium:
        return AppTheme.padding8;
      case ButtonSize.large:
        return AppTheme.padding8;
    }
  }

  TextStyle _getTextStyle() {
    final baseStyle = AppTheme.button;
    double fontSize;

    switch (size) {
      case ButtonSize.small:
        fontSize = 14;
        break;
      case ButtonSize.medium:
        fontSize = 16;
        break;
      case ButtonSize.large:
        fontSize = 18;
        break;
    }

    return baseStyle.copyWith(
      fontSize: fontSize,
      color: _getContentColor(),
    );
  }

  Color _getContentColor() {
    if (isDisabled) {
      return _getBaseContentColor().withOpacity(0.7);
    }
    return _getBaseContentColor();
  }

  Color _getBaseContentColor() {
    switch (type) {
      case ButtonType.primary:
        return textColor ?? AppTheme.onPrimaryColor;
      case ButtonType.secondary:
        return textColor ?? AppTheme.onSecondaryColor;
      case ButtonType.outlined:
      case ButtonType.text:
        return textColor ?? AppTheme.primaryColor;
      case ButtonType.danger:
        return textColor ?? AppTheme.onErrorColor;
      case ButtonType.success:
        return textColor ?? Colors.white;
    }
  }

  Color _getLoadingColor() {
    switch (type) {
      case ButtonType.primary:
        return AppTheme.onPrimaryColor;
      case ButtonType.secondary:
        return AppTheme.onSecondaryColor;
      case ButtonType.outlined:
      case ButtonType.text:
        return AppTheme.primaryColor;
      case ButtonType.danger:
        return AppTheme.onErrorColor;
      case ButtonType.success:
        return Colors.white;
    }
  }
}

/// Icon button with consistent styling
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final bool isLoading;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 48.0;
    final effectiveIconSize = iconSize ?? AppTheme.iconSizeMedium;

    Widget child = isLoading
        ? SizedBox(
            width: effectiveIconSize,
            height: effectiveIconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                iconColor ?? AppTheme.primaryColor,
              ),
            ),
          )
        : Icon(
            icon,
            size: effectiveIconSize,
            color: iconColor ?? AppTheme.primaryColor,
          );

    child = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveSize / 2),
      ),
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: child,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
      ),
    );

    return child;
  }
}

/// Floating action button with consistent styling
class CustomFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isExtended;
  final String? label;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isExtended = false,
    this.label,
    this.isLoading = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppTheme.secondaryColor;
    final effectiveIconColor = iconColor ?? AppTheme.onSecondaryColor;

    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveIconColor,
        icon: isLoading
            ? SizedBox(
                width: AppTheme.iconSizeMedium,
                height: AppTheme.iconSizeMedium,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveIconColor),
                ),
              )
            : Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveIconColor,
      child: isLoading
          ? SizedBox(
              width: AppTheme.iconSizeMedium,
              height: AppTheme.iconSizeMedium,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveIconColor),
              ),
            )
          : Icon(icon),
    );
  }
}
