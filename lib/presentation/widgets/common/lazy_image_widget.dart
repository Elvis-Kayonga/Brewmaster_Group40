// lib/presentation/widgets/common/lazy_image_widget.dart
//
// Lazy-loading image widget with fade-in transition and in-memory caching.
// Uses Image.network with cacheWidth / cacheHeight hints to reduce decode
// memory on low-end devices (requirement 14.5 — 2 GB RAM target).
//
// Requirements: 14.5
// Developer: Developer 6

import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Lazy-loading network image with fade-in animation and thumbnail support.
///
/// Supply [thumbnailUrl] to load a low-res preview first, then swap to the
/// full [imageUrl] once the high-res version is ready.
class LazyImageWidget extends StatelessWidget {
  /// Full-resolution image URL. May be null while loading.
  final String? imageUrl;

  /// Optional low-resolution preview URL shown while [imageUrl] loads.
  final String? thumbnailUrl;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Target decode width in logical pixels — passed as [cacheWidth] to reduce
  /// GPU memory usage. Defaults to null (natural size).
  final int? cacheWidth;

  /// Target decode height in logical pixels.
  final int? cacheHeight;

  /// Widget shown while the image is loading. Defaults to a grey shimmer.
  final Widget? placeholder;

  /// Widget shown on load error. Defaults to a broken-image icon.
  final Widget? errorWidget;

  /// Duration of the fade-in animation.
  final Duration fadeDuration;

  const LazyImageWidget({
    super.key,
    this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.errorWidget,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        // Show thumbnail (or shimmer) until the first frame arrives
        return AnimatedCrossFade(
          firstChild: _buildPlaceholder(),
          secondChild: child,
          crossFadeState: frame == null
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: fadeDuration,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return thumbnailUrl != null && thumbnailUrl!.isNotEmpty
            ? _ThumbnailPreview(
                url: thumbnailUrl!,
                width: width,
                height: height,
                fit: fit,
              )
            : _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => _buildError(),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          child: const Center(
            child: Icon(Icons.image_outlined,
                color: AppTheme.textSecondary, size: 32),
          ),
        );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppTheme.errorColor.withValues(alpha: 0.05),
          child: const Center(
            child: Icon(Icons.broken_image_outlined,
                color: AppTheme.textSecondary, size: 32),
          ),
        );
  }
}

/// Shows a blurred thumbnail preview while the high-res image loads.
class _ThumbnailPreview extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const _ThumbnailPreview({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ImageFiltered(
        imageFilter: const ColorFilter.mode(
          Colors.transparent,
          BlendMode.srcOver,
        ),
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          // Low-res thumbnail: decode at ¼ width to save memory
          cacheWidth: width != null ? (width! / 4).round() : null,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
