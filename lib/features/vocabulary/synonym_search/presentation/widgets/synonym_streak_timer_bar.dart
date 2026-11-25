import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Top Mastery HUD combining the live combo flame pill and countdown timer.
///
/// Reserves explicit right-edge clearance (`>= 56.w`) so [GameScaffold]'s
/// floating peeking mascot never overlaps interactive or readable timer UI.
class SynonymStreakTimerBar extends StatelessWidget {
  final GlobalKey<SpeedChallengeTimerState> timerKey;
  final int durationSeconds;
  final int comboStreak;
  final Color primaryColor;
  final VoidCallback onTimeUp;
  final ValueChanged<int>? onTick;
  final bool autoStart;

  const SynonymStreakTimerBar({
    super.key,
    required this.timerKey,
    required this.durationSeconds,
    required this.comboStreak,
    required this.primaryColor,
    required this.onTimeUp,
    this.onTick,
    this.autoStart = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasHotStreak = comboStreak >= 2;
    final pillColor = hasHotStreak
        ? AppColors.amber500
        : (comboStreak == 1 ? AppColors.emerald500 : primaryColor);

    return Padding(
      // Reserve >= 56dp on the right for VocabularyPeekingMascot overlay.
      padding: EdgeInsets.only(right: math.max(56.0, 58.w)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: VowlMotion.shouldReduceMotion(context)
                ? Duration.zero
                : VowlMotion.fast,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: isDark ? 0.24 : 0.14),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: pillColor.withValues(alpha: hasHotStreak ? 0.8 : 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasHotStreak
                      ? Icons.local_fire_department_rounded
                      : Icons.bolt_rounded,
                  size: 16.sp,
                  color: isDark ? AppColors.slate50 : pillColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  comboStreak > 0 ? 'x$comboStreak' : 'Ready',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.slate50 : pillColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: SpeedChallengeTimer(
              key: timerKey,
              durationSeconds: durationSeconds,
              primaryColor: primaryColor,
              onTimeUp: onTimeUp,
              onTick: onTick,
              autoStart: autoStart,
            ),
          ),
        ],
      ),
    );
  }
}
