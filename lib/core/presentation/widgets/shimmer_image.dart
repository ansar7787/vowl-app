import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// A premium, theme-adaptive cached network image that displays a high-performance
/// shimmer loader with hardware-isolated repaints during the loading lifecycle.
class ShimmerImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackIcon;

  const ShimmerImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Slate/Ice palettes matching Vowl's design system
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final placeholderBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final iconColor = isDark ? Colors.white24 : Colors.black26;

    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: placeholderBg,
        child: fallbackIcon ?? Icon(Icons.person, color: iconColor),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => RepaintBoundary(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: placeholderBg,
        child: const Icon(Icons.error_outline, color: Colors.redAccent),
      ),
    );
  }
}
