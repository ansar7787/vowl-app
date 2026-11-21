import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Stat indicator widget displaying Mastered count, Due count, and Average Retention.
class FlashcardVaultStatsBar extends StatelessWidget {
  final int totalCount;
  final int dueCount;
  final int avgRetention;
  final bool isDark;
  final bool isLandscape;

  const FlashcardVaultStatsBar({
    super.key,
    required this.totalCount,
    required this.dueCount,
    required this.avgRetention,
    required this.isDark,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('MASTERED', '$totalCount', AppColors.indigo500),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildCard(
            'TO REVIEW',
            '$dueCount',
            dueCount > 0 ? AppColors.rose500 : AppColors.emerald500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildCard(
            'RETENTION',
            '$avgRetention%',
            avgRetention >= 70 ? AppColors.emerald500 : Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String val, Color color) => Container(
    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? AppColors.slate400 : AppColors.slate600,
          ),
        ),
      ],
    ),
  );
}
