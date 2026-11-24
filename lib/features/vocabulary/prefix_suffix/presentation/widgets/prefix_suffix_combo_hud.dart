import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Heads-Up Display for the Prefix & Suffix Mastery Morpheme Precision Slicer.
///
/// Features:
/// - Real-time countdown timer bar with dynamic color transitions (Emerald -> Amber -> Red).
/// - Urgent pulsating warning when time is critically low (< 2 seconds).
/// - Dynamic flame streak combo multiplier badge (1x to 10x).
class PrefixSuffixComboHud extends StatelessWidget {
  /// Fraction of remaining time between 0.0 and 1.0.
  final double timeFraction;

  /// Remaining seconds as an integer display.
  final int secondsRemaining;

  /// Current combo multiplier level (1x to 10x).
  final int comboMultiplier;

  /// Current consecutive correct streak count.
  final int currentStreak;

  const PrefixSuffixComboHud({
    super.key,
    required this.timeFraction,
    required this.secondsRemaining,
    this.comboMultiplier = 1,
    this.currentStreak = 0,
  });

  Color _getTimerColor() {
    if (timeFraction > 0.5) {
      return AppColors.emerald500;
    } else if (timeFraction > 0.25) {
      return AppColors.amber500;
    } else {
      return AppColors.red500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = _getTimerColor();
    final isCritical = secondsRemaining <= 2 && secondsRemaining > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.slate800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCritical
              ? AppColors.red500.withValues(alpha: 0.8)
              : AppColors.slate700,
          width: isCritical ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Combo Badge
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      AnimatedScale(
                        scale: comboMultiplier > 1 ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 20.sp,
                          color: comboMultiplier > 1
                              ? AppColors.amber500
                              : AppColors.slate500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${comboMultiplier}x Combo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: comboMultiplier > 1
                              ? AppColors.amber500
                              : AppColors.slate400,
                        ),
                      ),
                      if (currentStreak > 1) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$currentStreak Streak',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Countdown Display
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16.sp, color: timerColor),
                  SizedBox(width: 4.w),
                  Text(
                    '${secondsRemaining}s',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Timer Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: SizedBox(
              height: 6.h,
              child: Stack(
                children: [
                  Container(width: double.infinity, color: AppColors.slate700),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: timeFraction.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: timerColor,
                        boxShadow: isCritical
                            ? [
                                BoxShadow(
                                  color: AppColors.red500.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
