import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    final baseColor = isDark ? AppColors.slate800 : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? const Color(0xFF334155)
        : AppColors.slate100;
    final placeholderBg = isDark ? AppColors.slate900 : const Color(0xFFF8FAFC);
    final iconColor = isDark ? Colors.white24 : Colors.black26;

    if (imageUrl.isEmpty) {
      return Semantics(
        image: true,
        label:
            semanticsLabel ??
            context.tr(
              'common.image_placeholder',
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
          child: Icon(Icons.error_outline, color: tokens.gameIncorrect),
        ),
      ),
    );
  }
}
