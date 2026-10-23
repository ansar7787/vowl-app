import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Badge displaying the target word or data item to scan for within the passage.
class SkimmingScanningTargetBadge extends StatelessWidget {
  /// Target word or phrase to locate.
  final String item;

  /// Theme accent color applied to badge borders and text.
  final Color color;

  /// Creates a [SkimmingScanningTargetBadge] widget.
  const SkimmingScanningTargetBadge({
    super.key,
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.04 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            color: color,
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              "FIND: ${item.toUpperCase()}",
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

