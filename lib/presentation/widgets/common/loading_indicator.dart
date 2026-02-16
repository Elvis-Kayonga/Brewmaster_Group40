import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Loading indicator size enumeration
enum LoadingSize { small, medium, large }

/// Loading indicator widget following Clean Architecture principles
/// Requirements: 10.4, 10.5, 16.1
/// Developer: Developer 6
class LoadingIndicator extends StatelessWidget {
  /// Size of the loading indicator
  final LoadingSize size;

  /// Color of the loading indicator
  final Color? color;

  /// Stroke width of the indicator
  final double? strokeWidth;

  /// Optional message to display below the indicator
  final String? message;

  /// Whether to center the indicator in available space
  final bool centered;

  const LoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    this.color,
    this.strokeWidth,
    this.message,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primaryColor,
        ),
      ),
    );

    if (message != null) {
      indicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: AppTheme.padding16),
          Text(
            message!,
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (centered) {
      indicator = Center(child: indicator);
    }

    return indicator;
  }

  double _getSize() {
    switch (size) {
      case LoadingSize.small:
        return 20.0;
      case LoadingSize.medium:
        return 36.0;
      case LoadingSize.large:
        return 48.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
    }
  }
}

/// Inline loading indicator for buttons or small spaces
class InlineLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const InlineLoadingIndicator({super.key, this.color, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.onPrimaryColor,
        ),
      ),
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  /// Child widget to display behind the overlay
  final Widget child;

  /// Whether the loading overlay is visible
  final bool isLoading;

  /// Loading message
  final String? message;

  /// Background color of the overlay
  final Color? overlayColor;

  /// Whether the overlay should block interactions
  final bool barrierDismissible;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.overlayColor,
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: GestureDetector(
              onTap: barrierDismissible ? () {} : null,
              child: Container(
                color: overlayColor ?? Colors.black.withValues(alpha: 0.5),
                child: LoadingIndicator(
                  message: message,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading placeholder for content
class ShimmerLoading extends StatefulWidget {
  /// Width of the shimmer
  final double? width;

  /// Height of the shimmer
  final double? height;

  /// Border radius of the shimmer
  final double borderRadius;

  /// Base color for the shimmer effect
  final Color? baseColor;

  /// Highlight color for the shimmer effect
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.borderRadiusMedium,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Loading state wrapper that shows loading, error, or content
class LoadingStateWidget<T> extends StatelessWidget {
  /// Whether data is loading
  final bool isLoading;

  /// Error message if loading failed
  final String? errorMessage;

  /// Data to display
  final T? data;

  /// Builder for content when data is available
  final Widget Function(T data) contentBuilder;

  /// Loading widget to display
  final Widget? loadingWidget;

  /// Error widget to display
  final Widget Function(String error)? errorBuilder;

  /// Empty state widget
  final Widget? emptyWidget;

  /// Retry callback for error state
  final VoidCallback? onRetry;

  const LoadingStateWidget({
    super.key,
    required this.isLoading,
    required this.data,
    required this.contentBuilder,
    this.errorMessage,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const LoadingIndicator();
    }

    if (errorMessage != null) {
      if (errorBuilder != null) {
        return errorBuilder!(errorMessage!);
      }
      return _buildDefaultError();
    }

    if (data == null) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return contentBuilder(data as T);
  }

  Widget _buildDefaultError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: AppTheme.iconSizeXLarge,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.padding16),
          Text(
            errorMessage!,
            style: AppTheme.body.copyWith(color: AppTheme.errorColor),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppTheme.padding16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
