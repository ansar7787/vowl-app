import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/theme/vowl_motion.dart';

class DialectDrillRegionMap extends StatelessWidget {
  final String region;
  final Color color;
  final bool isDark;

  const DialectDrillRegionMap({
    super.key,
    required this.region,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    IconData iconData = Icons.public;
    if (region.contains('United Kingdom')) {
      iconData = Icons.location_on_outlined;
    } else if (region.contains('United States')) {
      iconData = Icons.location_on_outlined;
    }

    final cardBg = isDark
        ? Color.alphaBlend(color.withValues(alpha: 0.08), const Color(0xFF1E2230))
        : Color.alphaBlend(color.withValues(alpha: 0.04), Colors.white);

    Widget card = Container(
      constraints: BoxConstraints(maxWidth: 300.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.16 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 20.r),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TARGET REGION",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    region.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!reduceMotion) {
      card = card.animate().fadeIn(duration: 350.ms).slideY(begin: 0.15);
    }

    return card;
  }
}
