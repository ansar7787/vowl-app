import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Single numbered rule item (1, 2, 3...) in the mission briefing overlay.
///
/// Designed with deliberate typographic contrast, high-legibility sizing,
/// tactile squircle badge, and solid surface styling without neon glows.
class QuestBriefingRuleItem extends StatelessWidget {
  final int index;
  final String rule;
  final Color primaryColor;
  final bool isLast;

  const QuestBriefingRuleItem({
    super.key,
    required this.index,
    required this.rule,
    required this.primaryColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    // High-contrast, standard text colors across modes
    final textCol = isMidnight
        ? const Color(0xFFF4F4F5) // Zinc-100
        : (isDark
              ? const Color(0xFFE4E4E7) // Zinc-200
              : const Color(0xFF1E293B)); // Slate-800

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek squircle badge
          Container(
            width: 22.r,
            height: 22.r,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: isMidnight ? 0.20 : (isDark ? 0.16 : 0.10),
              ),
              borderRadius: BorderRadius.circular(7.r),
              border: Border.all(
                color: primaryColor.withValues(
                  alpha: isMidnight ? 0.45 : (isDark ? 0.35 : 0.25),
                ),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                textScaler: const TextScaler.linear(1.0),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                color: textCol,
                fontWeight: FontWeight.w500,
                height: 1.44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

