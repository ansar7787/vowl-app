import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// 2026 Arcade Speed Fuse Timer bar with dynamic multi-tier color,
/// live countdown indicator, combo streak pill, and dynamic bonus time badge.
class TopicFusionTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final Color accentColor;
  final int bonusSecondsAdded;
  final int comboMultiplier;

  const TopicFusionTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.accentColor,
    this.bonusSecondsAdded = 0,
    this.comboMultiplier = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSec = totalSeconds > 0 ? totalSeconds : 30;
    final progress = (remainingSeconds / maxSec).clamp(0.0, 1.0);

    final Color timerColor;
    if (progress <= 0.25 || remainingSeconds <= 5) {
      timerColor = AppColors.rose500;
    } else if (progress <= 0.50 || remainingSeconds <= 12) {
      timerColor = AppColors.amber500;
    } else {
      timerColor = accentColor;
    }

    final isUrgent = remainingSeconds <= 5;
    final timerIcon = Icon(
      Icons.timer_outlined,
      color: timerColor,
      size: 15.r,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.10)
                : AppColors.slate900)
            : (isUrgent
                ? AppColors.rose500.withValues(alpha: 0.06)
                : Colors.white),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: timerColor.withValues(alpha: isUrgent ? 0.45 : 0.20),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Icon + TIME LEFT + Seconds pill
              Row(
                children: [
                  if (isUrgent && !VowlMotion.shouldReduceMotion(context))
                    timerIcon
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 400.ms,
                        )
                  else
                    timerIcon,
                  SizedBox(width: 6.w),
                  Text(
                    'TIME LEFT',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: timerColor,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${remainingSeconds}s',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: timerColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Right: Bonus badge & Combo Multiplier pill
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (bonusSecondsAdded > 0) ...[
                    _buildBonusBadge(context),
                    if (comboMultiplier > 1) SizedBox(width: 6.w),
                  ],
                  if (comboMultiplier > 1)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.amber500.withValues(alpha: 0.45),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 13.r,
                            color: AppColors.amber500,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            '${comboMultiplier}x COMBO',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.amber400
                                  : AppColors.amber600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 7.h),
          // Multi-Tier Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark ? AppColors.slate800 : AppColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 6.5.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusBadge(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.emerald500,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        '+${bonusSecondsAdded}s',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) {
      return badge;
    }

    return badge
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.25, end: 0, duration: 250.ms, curve: Curves.easeOutBack)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
  }
}
