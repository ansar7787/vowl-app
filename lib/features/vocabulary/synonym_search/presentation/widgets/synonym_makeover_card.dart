import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_makeover_inline_sentence.dart';

/// Interactive card for Learn Phase ("Sentence Makeover Studio").
///
/// Displays a real-world situation sentence with an inline tappable word slot
/// that swaps live between [SynonymMakeoverScenario.targetSlotWord] and
/// [SynonymMakeoverScenario.swappedWord], updating audio playback and revealing
/// the Native Ear Verdict without passive slide reading.
class SynonymMakeoverCard extends StatelessWidget {
  final SynonymMakeoverScenario scenario;
  final int scenarioIndex;
  final bool isSwapped;
  final Color primaryColor;
  final VoidCallback onToggleSwap;

  const SynonymMakeoverCard({
    super.key,
    required this.scenario,
    required this.scenarioIndex,
    required this.isSwapped,
    required this.primaryColor,
    required this.onToggleSwap,
  });

  String get _activeWord =>
      isSwapped ? scenario.swappedWord : scenario.targetSlotWord;

  String get _liveSpokenSentence {
    if (isSwapped &&
        scenario.isNaturalSwap &&
        scenario.spokenSentence.isNotEmpty) {
      return scenario.spokenSentence;
    }
    return scenario.beforeSentence.replaceAll('___', _activeWord);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.slate800.withValues(alpha: 0.92)
        : Colors.white;
    final borderColor = !isSwapped
        ? (isDark ? AppColors.slate700 : AppColors.slate200)
        : (scenario.isNaturalSwap ? AppColors.emerald500 : AppColors.rose500);
    final textPrimary = isDark ? AppColors.slate50 : AppColors.slate900;
    final textMuted = isDark ? AppColors.slate300 : AppColors.slate600;

    return AnimatedContainer(
      duration: VowlMotion.shouldReduceMotion(context)
          ? Duration.zero
          : VowlMotion.medium,
      curve: VowlMotion.defaultCurve,
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: isSwapped ? 1.8 : 1.2),
        boxShadow: [
          BoxShadow(
            color: (isSwapped ? borderColor : Colors.black).withValues(
              alpha: isDark ? 0.22 : 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TagPill(
                      label: scenario.situationTag,
                      color: primaryColor,
                      isDark: isDark,
                    ),
                    _EarStatusBadge(
                      isSwapped: isSwapped,
                      isNaturalSwap: scenario.isNaturalSwap,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              TtsSpeakerButtonWidget(
                text: _liveSpokenSentence,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SynonymMakeoverInlineSentence(
            beforeSentence: scenario.beforeSentence,
            activeWord: _activeWord,
            alternateWord: isSwapped
                ? scenario.targetSlotWord
                : scenario.swappedWord,
            isSwapped: isSwapped,
            isNaturalSwap: scenario.isNaturalSwap,
            primaryColor: primaryColor,
            textColor: textPrimary,
            isDark: isDark,
            slotKey: Key('makeover_slot_$scenarioIndex'),
            onTapSlot: onToggleSwap,
          ),
          SizedBox(height: 10.h),
          if (isSwapped)
            SynonymMakeoverVerdictBanner(
              isNatural: scenario.isNaturalSwap,
              verdictText: scenario.earVerdict,
              isDark: isDark,
            )
          else
            Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 16.sp, color: primaryColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Tap "${scenario.targetSlotWord}" to swap in "${scenario.swappedWord}" and test how it sounds.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _TagPill({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.slate50 : color,
        ),
      ),
    );
  }
}

class _EarStatusBadge extends StatelessWidget {
  final bool isSwapped;
  final bool isNaturalSwap;
  final bool isDark;

  const _EarStatusBadge({
    required this.isSwapped,
    required this.isNaturalSwap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSwapped) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate700 : AppColors.slate100,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          'Original',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.slate200 : AppColors.slate700,
          ),
        ),
      );
    }

    final color = isNaturalSwap ? AppColors.emerald600 : AppColors.rose700;
    final bg = isNaturalSwap
        ? (isDark ? AppColors.emerald950 : AppColors.emerald50)
        : (isDark ? AppColors.red900.withValues(alpha: 0.65) : AppColors.red50);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNaturalSwap
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            size: 14.sp,
            color: isDark ? AppColors.slate50 : color,
          ),
          SizedBox(width: 4.w),
          Text(
            isNaturalSwap ? 'Natural Fit' : 'Awkward Fit',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slate50 : color,
            ),
          ),
        ],
      ),
    );
  }
}
