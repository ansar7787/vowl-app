import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Single numbered rule item (1, 2, 3...) in the mission briefing overlay.
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
    final textCol =
        isDark ? Colors.white.withValues(alpha: 0.88) : AppColors.slate700;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18.r,
            height: 18.r,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.35),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  height: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              rule,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                color: textCol,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
