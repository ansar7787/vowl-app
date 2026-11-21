import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Celebration banner shown when all category trays in Practice are completed.
class TopicPracticeCelebrationCard extends StatelessWidget {
  const TopicPracticeCelebrationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.emerald500.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.emerald500,
            size: 22.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Groups Completed!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'You anchored all words to their categories. Ready for the timed challenge!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helpful non-punitive coaching message banner shown when an ESL learner
/// taps a word belonging to a different category in Practice.
class TopicPracticeCoachingBanner extends StatelessWidget {
  final String message;

  const TopicPracticeCoachingBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 4.h, bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.amber500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.amber500.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.amber500,
            size: 16.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.amber500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
