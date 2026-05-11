import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KidsImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double? size;
  final Color? iconColor;

  const KidsImage({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
    this.size,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if it's a network URL
    if (imageUrl!.startsWith('http') || imageUrl!.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : Colors.blueAccent,
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    // Check if it's a local asset
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // Check if it's an emoji (Free high-quality visual)
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F191}-\u{1F251}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{3030}\u{2B50}\u{2B55}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2122}\u{2139}\u{24C2}\u{3297}\u{3299}\u{203C}\u{2049}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2604}\u{260E}\u{2611}\u{2614}-\u{2615}\u{2618}\u{261D}\u{2620}\u{2622}-\u{2623}\u{2626}\u{262A}\u{262E}-\u{262F}\u{2638}-\u{263A}\u{2640}\u{2642}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2692}-\u{2694}\u{2696}-\u{2697}\u{2699}\u{269B}-\u{269C}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26B0}-\u{26B1}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26C8}\u{26CE}-\u{26CF}\u{26D1}\u{26D3}-\u{26D4}\u{26E9}-\u{26EA}\u{26F0}-\u{26F5}\u{26F7}-\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270D}\u{270F}\u{2712}\u{2714}\u{2716}\u{271D}-\u{271E}\u{2721}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2763}-\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{27BF}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{E000}-\u{F8FF}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F251}\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}]', unicode: true);
    if (emojiRegex.hasMatch(imageUrl!)) {
      return Center(
        child: Text(
          imageUrl!,
          style: TextStyle(fontSize: size ?? 80.sp),
        ),
      );
    }

    // If it's a prompt (e.g., "3d clay lion"), show the fallback icon
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: size ?? 80.sp,
        color: iconColor ?? Colors.grey[300],
      ),
    );
  }
}
