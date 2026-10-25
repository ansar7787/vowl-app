import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Production-grade circular user avatar that guarantees a 1:1 circular center crop
/// (`BoxFit.cover`, `Alignment.center`) across all screen sizes and aspect ratios,
/// perfectly matching the WhatsApp-style profile picture presentation.
///
/// Seamlessly handles:
/// - Remote network URLs (`http://`, `https://`) with cached memory decoding & shimmer placeholder.
/// - Local file paths (`/data/...`, `file://...`) during immediate pick/upload preview.
/// - Graceful fallback icon when [photoUrl] is null, empty, or fails to load.
class UserAvatar extends StatelessWidget {
  /// Remote URL or local file path to the user's avatar image.
  final String? photoUrl;

  /// Diameter of the circular avatar in logical pixels.
  final double size;

  /// Optional border surrounding the avatar (e.g., golden tier ring).
  final BoxBorder? border;

  /// Background color shown behind the avatar or during loading.
  final Color? backgroundColor;

  /// Fallback icon shown when no image is available or on error.
  final IconData fallbackIcon;

  /// Size of the fallback icon. Defaults to 50% of [size].
  final double? iconSize;

  /// Color of the fallback icon.
  final Color? iconColor;

  /// Hero animation tag for smooth transitions across screens.
  final String? heroTag;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.size,
    this.border,
    this.backgroundColor,
    this.fallbackIcon = Icons.person_rounded,
    this.iconSize,
    this.iconColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.slate100);
    final resolvedIconColor = iconColor ??
        (isDark ? Colors.white38 : AppColors.slate400);
    final resolvedIconSize = iconSize ?? (size * 0.52);

    final widgetChild = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolvedBg,
        border: border,
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: _buildImageContent(
            context,
            isDark,
            resolvedBg,
            resolvedIconColor,
            resolvedIconSize,
          ),
        ),
      ),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: widgetChild);
    }

    return widgetChild;
  }

  Widget _buildImageContent(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color fallbackIconColor,
    double resolvedIconSize,
  ) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(
          fallbackIcon,
          color: fallbackIconColor,
          size: resolvedIconSize,
        ),
      );
    }

    // Check if it's a remote HTTP/HTTPS URL
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    if (isNetwork) {
      final cacheSize = (size * 2.5).round().clamp(80, 800);
      final shimmerBase =
          isDark ? AppColors.slate800 : AppColors.slate200;
      final shimmerHighlight =
          isDark ? AppColors.slate700 : AppColors.slate100;

      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: shimmerBase,
          highlightColor: shimmerHighlight,
          child: Container(
            width: size,
            height: size,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            fallbackIcon,
            color: fallbackIconColor,
            size: resolvedIconSize,
          ),
        ),
      );
    }

    // Otherwise, treat as a local filesystem image (e.g. freshly picked from camera/gallery)
    final filePath = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
    final file = File(filePath);

    return Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Icon(
          fallbackIcon,
          color: fallbackIconColor,
          size: resolvedIconSize,
        ),
      ),
    );
  }
}

