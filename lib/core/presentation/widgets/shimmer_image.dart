import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Theme-adaptive cached network image with a high-performance shimmer
/// placeholder. Hardware-isolated repaints during the loading lifecycle.
class ShimmerImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackIcon;
  final String? semanticsLabel;

  const ShimmerImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);
    final placeholderBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final iconColor = isDark ? Colors.white24 : Colors.black26;

    if (imageUrl.isEmpty) {
      return Semantics(
        image: true,
        label:
            semanticsLabel ??
            context.tr(
              'common.image_placeholder', fallback: 'Image',
              fallback: 'Image placeholder',
            ),
        child: Container(
          width: width,
          height: height,
          color: placeholderBg,
          child: fallbackIcon ?? Icon(Icons.person, color: iconColor),
        ),
      );
    }

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => RepaintBoundary(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(width: width, height: height, color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: placeholderBg,
          child: const Icon(Icons.error_outline, color: Colors.redAccent),
        ),
      ),
    );
  }
}
