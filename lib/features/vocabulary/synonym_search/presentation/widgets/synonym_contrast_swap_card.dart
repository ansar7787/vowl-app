import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_practice_shared.dart';

/// Contrast Swap drill card in Practice Phase.
///
/// Challenges the learner to assign paired synonyms to two contrasting
/// real-world sentence slots simultaneously, checking nuance precision rather
/// than isolated dictionary recall.
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promptColor = isDark ? AppColors.slate100 : AppColors.slate900;

    return ShakeableWrapper(
      shakeCount: shakeCount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SynonymDrillBadge(
                label: 'CONTRAST SWAP',
                cefr: exercise.cefr,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              const Spacer(),
              if (!(hasChecked && isCorrect))
                Flexible(
                  child: Text(
                    'Tap word to fill slot',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate300 : AppColors.slate500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            exercise.prompt,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: promptColor,
              height: 1.35,
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
        : (isDark ? AppColors.slate700 : AppColors.slate200);

    final parts = slot.sentenceWithBlank.split('___');
    final beforeWords = _tokenize(parts.isNotEmpty ? parts.first : '');
    final afterWords = parts.length > 1
        ? _tokenize(parts.sublist(1).join(' '))
        : const [];
    final textColor = isDark ? AppColors.slate100 : AppColors.slate900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.92)
            : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: borderColor,
          width: (isFocused || hasChecked) ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  slot.contextTag,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate100 : primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (isSolved)
                TtsSpeakerButtonWidget(
                  text: slot.sentenceWithBlank.replaceAll(
                    '___',
                    slot.correctWord,
                  ),
                  color: primaryColor,
                  size: 18,
                ),
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
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              Semantics(
                button: true,
                label: assignedWord == null
                    ? 'Slot ${slotIndex + 1}, empty, tap to focus'
                    : 'Slot ${slotIndex + 1}, $assignedWord, tap to clear',
                child: ScaleButton(
                  key: Key('contrast_slot_$slotIndex'),
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
                            ? AppColors.emerald500.withValues(alpha: 0.16)
                            : slotWrong
                            ? AppColors.rose500.withValues(alpha: 0.16)
                            : primaryColor.withValues(
                                alpha: isFocused ? 0.18 : 0.08,
                              ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: borderColor,
                          width: isFocused ? 1.8 : 1.2,
                        ),
                      ),
                      child: Text(
                        assignedWord ?? '______',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w800,
                          color: assignedWord == null
                              ? (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500)
                              : (isDark
                                    ? AppColors.slate50
                                    : AppColors.slate900),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              for (final w in afterWords)
                Text(
                  w,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _tokenize(String raw) {
    return raw.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }
}
