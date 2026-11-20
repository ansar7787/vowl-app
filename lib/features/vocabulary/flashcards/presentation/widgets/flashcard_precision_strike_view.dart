import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import '../controllers/flashcard_controller.dart';

/// Stage 2 of Flashcard Mastery: Precision Sentence Strike.
///
/// Learners rapidly select the exact target word to slot into the context sentence.
class FlashcardPrecisionStrikeView extends StatelessWidget {
  final VocabularyQuest quest;
  final FlashcardMasteryController controller;
  final List<String> candidateWords;
  final bool isDark;

  const FlashcardPrecisionStrikeView({
    super.key,
    required this.quest,
    required this.controller,
    required this.candidateWords,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final targetWord = quest.word?.toLowerCase() ?? '';
    final sentence =
        quest.contextSentence ??
        quest.example ??
        'The team verified the _____ data.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.gps_fixed_rounded, size: 16.r, color: Colors.cyanAccent),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'STAGE 2: PRECISION SENTENCE STRIKE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.cyanAccent : Colors.teal.shade800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // Sentence with illuminated gap
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : AppColors.slate50,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? AppColors.slate800 : AppColors.slate300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 10.r,
              ),
            ],
          ),
          child: Text(
            sentence,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        // Candidate Words Column
        ValueListenableBuilder<int?>(
          valueListenable: controller.selectedCandidateIndex,
          builder: (context, selectedIdx, _) {
            return Column(
              children: List.generate(candidateWords.length, (idx) {
                final word = candidateWords[idx];
                final isSelected = selectedIdx == idx;
                final isTarget =
                    word.trim().toLowerCase() ==
                    targetWord.trim().toLowerCase();

                Color borderCol = isDark
                    ? AppColors.slate800
                    : AppColors.slate200;
                Color bgCol = isDark ? AppColors.slate900 : Colors.white;

                if (isSelected) {
                  if (isTarget) {
                    borderCol = Colors.green;
                    bgCol = Colors.green.withValues(alpha: 0.15);
                  } else {
                    borderCol = Colors.red;
                    bgCol = Colors.red.withValues(alpha: 0.15);
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: ScaleButton(
                    key: ValueKey('candidate_$idx'),
                    onTap: () => controller.strikeCandidateWord(
                      index: idx,
                      selectedWord: word,
                      targetWord: targetWord,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgCol,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderCol,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.04,
                            ),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28.r,
                            height: 28.r,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              word.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              isTarget
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 20.r,
                              color: isTarget ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
