import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Top Mastery HUD combining the live streak badge and countdown timer.
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
              gradient: hasHotStreak
                  ? LinearGradient(
                      colors: [
                        AppColors.amber500.withValues(
                          alpha: isDark ? 0.34 : 0.22,
                        ),
                        AppColors.orange500.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                      ],
                    )
                  : null,
              color: hasHotStreak
                  ? null
                  : pillColor.withValues(alpha: isDark ? 0.24 : 0.14),
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(
                color: pillColor.withValues(alpha: hasHotStreak ? 0.85 : 0.45),
              ),
            ),
            child: AnimatedSwitcher(
              duration: VowlMotion.shouldReduceMotion(context)
                  ? Duration.zero
                  : VowlMotion.fast,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Row(
                key: ValueKey<int>(comboStreak),
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
                    style: SynonymUiTokens.controlLabel(
                      color: isDark ? AppColors.slate50 : pillColor,
                    ),
                  ),
                ],
              ),
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
