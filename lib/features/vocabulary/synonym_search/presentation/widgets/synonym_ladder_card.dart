import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_practice_shared.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Practice card that orders 3 related synonyms from mild to strong or formal.
class SynonymLadderCard extends StatelessWidget {
  final SynonymPracticeExercise exercise;
  final List<String?> placements;
  final int? focusedRungIndex;
  final bool hasChecked;
  final bool isCorrect;
  final bool showHint;
  final int shakeCount;
  final String? feedbackMessage;
  final Color primaryColor;
  final ValueChanged<int> onTapRung;
  final ValueChanged<String> onPlaceWord;

  const SynonymLadderCard({
    super.key,
    required this.exercise,
    required this.placements,
    required this.focusedRungIndex,
    required this.hasChecked,
    required this.isCorrect,
    required this.showHint,
    required this.shakeCount,
    required this.feedbackMessage,
    required this.primaryColor,
    required this.onTapRung,
    required this.onPlaceWord,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final words = exercise.shuffledWords;
    final rungCount = exercise.orderedWords.length;

    return ShakeableWrapper(
      shakeCount: shakeCount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                SynonymDrillBadge(
                  label: 'Word order',
                  cefr: exercise.cefr,
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
                if (exercise.scaleAxis.isNotEmpty)
                  Text(
                    exercise.scaleAxis,
                    style: SynonymUiTokens.badgeLabel(
                      color: SynonymUiTokens.mutedText(isDark),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            exercise.prompt,
            style: SynonymUiTokens.sectionHeading(
              color: SynonymUiTokens.primaryText(isDark),
            ),
          ),
          SizedBox(height: 14.h),
          for (int i = 0; i < rungCount; i++) ...[
            _LadderRungTile(
              key: Key('ladder_rung_$i'),
              rungIndex: i,
              totalRungs: rungCount,
              poleHint: i == 0
                  ? exercise.lowLabel
                  : (i == rungCount - 1 ? exercise.highLabel : 'Moderate'),
              placedWord: i < placements.length ? placements[i] : null,
              expectedWord: exercise.orderedWords[i],
              isFocused: focusedRungIndex == i && !(hasChecked && isCorrect),
              hasChecked: hasChecked,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: () => onTapRung(i),
            ),
            if (i < rungCount - 1) SizedBox(height: 10.h),
          ],
          SizedBox(height: 16.h),
          Center(
            child: Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i < words.length; i++)
                  SynonymPracticeWordPill(
                    key: Key('ladder_bank_word_$i'),
                    word: words[i],
                    isUsed: placements.any(
                      (p) => p?.toLowerCase() == words[i].toLowerCase(),
                    ),
                    primaryColor: primaryColor,
                    isDark: isDark,
                    minWidth: 84,
                    onTap: () => onPlaceWord(words[i]),
                  ),
              ],
            ),
          ),
          if (showHint && exercise.hint.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SynonymPracticeBanner(
              icon: Icons.lightbulb_outline_rounded,
              text: exercise.hint,
              accent: AppColors.amber600,
              isDark: isDark,
            ),
          ],
          if (hasChecked && feedbackMessage != null) ...[
            SizedBox(height: 12.h),
            SynonymPracticeBanner(
              icon: isCorrect
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              text: feedbackMessage!,
              accent: isCorrect ? AppColors.emerald600 : AppColors.rose500,
              isDark: isDark,
              ttsText: isCorrect && exercise.spokenExample.isNotEmpty
                  ? exercise.spokenExample
                  : null,
              primaryColor: primaryColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _LadderRungTile extends StatelessWidget {
  final int rungIndex;
  final int totalRungs;
  final String poleHint;
  final String? placedWord;
  final String expectedWord;
  final bool isFocused;
  final bool hasChecked;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _LadderRungTile({
    super.key,
    required this.rungIndex,
    required this.totalRungs,
    required this.poleHint,
    required this.placedWord,
    required this.expectedWord,
    required this.isFocused,
    required this.hasChecked,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMatch =
        hasChecked &&
        (placedWord ?? '').trim().toLowerCase() ==
            expectedWord.trim().toLowerCase();
    final bool isMiss = hasChecked && !isMatch;

    final Color border = isMatch
        ? AppColors.emerald500
        : isMiss
        ? AppColors.rose500
        : isFocused
        ? primaryColor
        : SynonymUiTokens.subtleBorder(isDark);

    final double strengthFraction = totalRungs <= 1
        ? 1.0
        : ((rungIndex + 1) / totalRungs).clamp(0.28, 1.0);
    final Color rungAccent = Color.lerp(
      primaryColor.withValues(alpha: 0.72),
      primaryColor,
      strengthFraction,
    )!;

    return Semantics(
      button: true,
      label: placedWord == null
          ? 'Row ${rungIndex + 1}, $poleHint, empty'
          : 'Row ${rungIndex + 1}, $placedWord, tap to clear',
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 120),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: placedWord != null
                  ? primaryColor.withValues(
                      alpha: isDark
                          ? 0.08 + (rungIndex * 0.05)
                          : 0.03 + (rungIndex * 0.025),
                    )
                  : SynonymUiTokens.cardSurface(isDark),
              borderRadius: BorderRadius.circular(
                SynonymUiTokens.controlRadius,
              ),
              border: Border.all(
                color: border,
                width: (isFocused || hasChecked) ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rungAccent.withValues(
                          alpha: isDark ? 0.28 : 0.14,
                        ),
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.badgeRadius,
                        ),
                      ),
                      child: Text(
                        '${rungIndex + 1}',
                        style: SynonymUiTokens.controlLabel(
                          color: isDark ? AppColors.slate50 : rungAccent,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        placedWord ?? 'Place word here ($poleHint)',
                        style: placedWord == null
                            ? SynonymUiTokens.sentenceBody(
                                color: SynonymUiTokens.mutedText(isDark),
                              )
                            : SynonymUiTokens.interactiveWord(
                                color: SynonymUiTokens.primaryText(isDark),
                              ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate900 : AppColors.slate100,
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.badgeRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rungIndex == totalRungs - 1) ...[
                            Icon(
                              Icons.trending_up_rounded,
                              size: 13.sp,
                              color: isDark ? AppColors.slate200 : primaryColor,
                            ),
                            SizedBox(width: 3.w),
                          ],
                          Text(
                            poleHint,
                            style: SynonymUiTokens.badgeLabel(
                              color: SynonymUiTokens.mutedText(isDark),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: strengthFraction,
                    minHeight: 5.h,
                    backgroundColor: isDark
                        ? AppColors.slate900
                        : AppColors.slate100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMatch
                          ? AppColors.emerald500
                          : isMiss
                          ? AppColors.rose500
                          : rungAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
