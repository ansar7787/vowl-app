import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Single numbered rule item (1, 2, 3...) in the mission briefing overlay.
///
/// Designed with deliberate typographic contrast, high-legibility sizing,
/// and solid surface styling without neon glows or visual clutter.
class QuestBriefingRuleItem extends StatelessWidget {
  final int index;
  final String rule;
  final Color primaryColor;

  const QuestBriefingRuleItem({
    super.key,
    required this.index,
    required this.rule,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final textCol = isMidnight
        ? Colors.white
        : (isDark ? Colors.white.withValues(alpha: 0.90) : AppColors.slate700);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.r,
            height: 22.r,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.40 : 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w400,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
