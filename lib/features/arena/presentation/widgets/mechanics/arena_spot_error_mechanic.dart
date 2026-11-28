import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// Mechanic 5: Spot the Error 🎯
/// Independent implementation: sentence broken into tappable word tokens → tap wrong word.
class ArenaSpotErrorMechanic extends StatelessWidget {
  final ArenaChallenge challenge;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<int> onTapToken;

  const ArenaSpotErrorMechanic({
    super.key,
    required this.challenge,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTapToken,
  });

  void _handleTokenTap(int idx) {
    if (state.isAnswered) return;
    final isCorrect = idx == (challenge.errorTokenIndex ?? -1);
    if (isCorrect) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect(
          comboStep: state.currentQuestionIndex + 1,
        );
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playWrong();
      }
    }
    onTapToken(idx);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = challenge.sentenceTokens ?? challenge.correctAnswer.split(' ');
    final errorIdx = challenge.errorTokenIndex ?? -1;
    final isAnswered = state.isAnswered;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.cardSpacious),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: AppColors.rose500.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.target,
                      size: 14.sp,
                      color: AppColors.rose500,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'TAP THE WRONG WORD',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.rose500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // Interactive Tappable Word Chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.w,
                  runSpacing: 10.h,
                  children: List.generate(tokens.length, (idx) {
                    Color chipBg = isDark
                        ? AppColors.slate900
                        : AppColors.slate50;
                    Color chipBorder = borderColor;
                    Color chipText = textPrimary;

                    if (isAnswered) {
                      if (idx == errorIdx) {
                        chipBg = AppColors.emerald500.withValues(alpha: 0.2);
                        chipBorder = AppColors.emerald500;
                        chipText = AppColors.emerald500;
                      } else if (state.selectedOption == idx) {
                        chipBg = AppColors.rose500.withValues(alpha: 0.2);
                        chipBorder = AppColors.rose500;
                        chipText = AppColors.rose500;
                      }
                    }

                    return ScaleButton(
                      debounceDuration: Duration.zero,
                      onTap: isAnswered ? null : () => _handleTokenTap(idx),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: chipBorder, width: 1.5),
                        ),
                        child: Text(
                          tokens[idx],
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.w800,
                            color: chipText,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          if (isAnswered) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.slate100,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.lightbulb,
                        size: 15.sp,
                        color: AppColors.amber500,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          '${challenge.errorToken ?? ''} → ${challenge.correctedToken ?? ''}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            color: (state.isCorrect == true)
                                ? AppColors.emerald500
                                : AppColors.rose500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (challenge.explanation.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      challenge.explanation,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        height: 1.35,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
