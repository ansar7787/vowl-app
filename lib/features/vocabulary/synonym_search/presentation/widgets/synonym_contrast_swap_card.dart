import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_practice_shared.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_translatable_block.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_ui_tokens.dart';

/// Practice card that asks the learner to place paired synonyms into the
/// two matching everyday sentences.
class SynonymContrastSwapCard extends StatelessWidget {
  final SynonymPracticeExercise exercise;
  final List<String?> assignments;
  final int? focusedSlotIndex;
  final bool hasChecked;
  final bool isCorrect;
  final bool showHint;
  final int shakeCount;
  final String? feedbackMessage;
  final Color primaryColor;
  final ValueChanged<int> onTapSlot;
  final ValueChanged<String> onAssignWord;
  final VoidCallback? onSwapSlots;

  const SynonymContrastSwapCard({
    super.key,
    required this.exercise,
    required this.assignments,
    required this.focusedSlotIndex,
    required this.hasChecked,
    required this.isCorrect,
    required this.showHint,
    required this.shakeCount,
    required this.feedbackMessage,
    required this.primaryColor,
    required this.onTapSlot,
    required this.onAssignWord,
    this.onSwapSlots,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promptColor = SynonymUiTokens.primaryText(isDark);

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
                  label: 'Choose the word',
                  cefr: exercise.cefr,
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
                if (!(hasChecked && isCorrect))
                  Text(
                    'Tap a word to place it',
                    style: SynonymUiTokens.badgeLabel(
                      color: SynonymUiTokens.mutedText(isDark),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          SynonymTranslatableArea(
            textToTranslate: exercise.prompt,
            primaryColor: primaryColor,
            buttonSize: 16,
            builder: (context, translateAction, translatedBanner) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.prompt,
                        style: SynonymUiTokens.sectionHeading(
                          color: promptColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    translateAction,
                  ],
                ),
                ?translatedBanner,
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Center(
            child: Wrap(
              spacing: 12.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i < exercise.pairWords.length; i++)
                  SynonymPracticeWordPill(
                    key: Key('contrast_bank_word_$i'),
                    word: exercise.pairWords[i],
                    isUsed: assignments.any(
                      (a) =>
                          a?.toLowerCase() ==
                          exercise.pairWords[i].toLowerCase(),
                    ),
                    primaryColor: primaryColor,
                    isDark: isDark,
                    minWidth: 96,
                    onTap: () => onAssignWord(exercise.pairWords[i]),
                  ),
                if (onSwapSlots != null &&
                    assignments.length >= 2 &&
                    assignments.every((a) => a != null) &&
                    !(hasChecked && isCorrect))
                  SynonymPracticeSwapButton(
                    key: const Key('contrast_swap_both_btn'),
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: onSwapSlots!,
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          for (int i = 0; i < exercise.slots.length; i++) ...[
            _ContrastSlotCard(
              slotIndex: i,
              slot: exercise.slots[i],
              assignedWord: i < assignments.length ? assignments[i] : null,
              isFocused: focusedSlotIndex == i && !(hasChecked && isCorrect),
              hasChecked: hasChecked,
              isSolved: hasChecked && isCorrect,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: () => onTapSlot(i),
            ),
            if (i < exercise.slots.length - 1) SizedBox(height: 12.h),
          ],
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
            ),
          ],
        ],
      ),
    );
  }
}

class _ContrastSlotCard extends StatelessWidget {
  final int slotIndex;
  final SynonymContrastSlot slot;
  final String? assignedWord;
  final bool isFocused;
  final bool hasChecked;
  final bool isSolved;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ContrastSlotCard({
    required this.slotIndex,
    required this.slot,
    required this.assignedWord,
    required this.isFocused,
    required this.hasChecked,
    required this.isSolved,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool slotCorrect =
        hasChecked &&
        (assignedWord ?? '').trim().toLowerCase() ==
            slot.correctWord.trim().toLowerCase();
    final bool slotWrong = hasChecked && !slotCorrect;

    final Color borderColor = slotCorrect
        ? AppColors.emerald500
        : slotWrong
        ? AppColors.rose500
        : isFocused
        ? primaryColor
        : SynonymUiTokens.subtleBorder(isDark);

    final parts = slot.sentenceWithBlank.split('___');
    final beforeWords = _tokenize(parts.isNotEmpty ? parts.first : '');
    final afterWords = parts.length > 1
        ? _tokenize(parts.sublist(1).join(' '))
        : const [];
    final textColor = SynonymUiTokens.primaryText(isDark);
    final translatableSentence = isSolved
        ? slot.sentenceWithBlank.replaceAll('___', slot.correctWord)
        : slot.sentenceWithBlank;

    return SynonymTranslatableArea(
      textToTranslate: translatableSentence,
      primaryColor: primaryColor,
      buttonSize: 16,
      builder: (context, translateAction, translatedBanner) => Container(
        width: double.infinity,
        padding: SynonymUiTokens.cardPadding,
        decoration: BoxDecoration(
          color: SynonymUiTokens.cardSurface(isDark),
          borderRadius: BorderRadius.circular(SynonymUiTokens.cardRadius),
          border: Border.all(
            color: borderColor,
            width: (isFocused || hasChecked) ? 1.5 : 1.0,
          ),
          boxShadow: SynonymUiTokens.softCardShadow(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: SynonymUiTokens.badgePadding,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.22 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(
                          SynonymUiTokens.badgeRadius,
                        ),
                      ),
                      child: Text(
                        slot.contextTag,
                        style: SynonymUiTokens.badgeLabel(
                          color: isDark ? AppColors.slate100 : primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                translateAction,
                if (isSolved) ...[
                  SizedBox(width: 6.w),
                  TtsSpeakerButtonWidget(
                    text: slot.sentenceWithBlank.replaceAll(
                      '___',
                      slot.correctWord,
                    ),
                    color: primaryColor,
                    size: 18,
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5.w,
              runSpacing: 8.h,
              children: [
                for (final w in beforeWords)
                  Text(
                    w,
                    style: SynonymUiTokens.sentenceBody(color: textColor),
                  ),
                Semantics(
                  button: true,
                  label: assignedWord == null
                      ? 'Blank ${slotIndex + 1}, empty, tap to select'
                      : 'Blank ${slotIndex + 1}, $assignedWord, tap to clear',
                  child: ScaleButton(
                    key: Key('contrast_slot_$slotIndex'),
                    debounceDuration: const Duration(milliseconds: 120),
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 78,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: slotCorrect
                              ? AppColors.emerald500.withValues(alpha: 0.14)
                              : slotWrong
                              ? AppColors.rose500.withValues(alpha: 0.14)
                              : primaryColor.withValues(
                                  alpha: isFocused ? 0.16 : 0.08,
                                ),
                          borderRadius: BorderRadius.circular(
                            SynonymUiTokens.controlRadius,
                          ),
                          border: Border.all(
                            color: borderColor,
                            width: isFocused ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          assignedWord ?? '______',
                          textAlign: TextAlign.center,
                          style: assignedWord == null
                              ? SynonymUiTokens.sentenceBody(
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate500,
                                )
                              : SynonymUiTokens.interactiveWord(
                                  color: SynonymUiTokens.primaryText(isDark),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final w in afterWords)
                  Text(
                    w,
                    style: SynonymUiTokens.sentenceBody(color: textColor),
                  ),
              ],
            ),
            ?translatedBanner,
          ],
        ),
      ),
    );
  }

  List<String> _tokenize(String raw) {
    return raw.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }
}
