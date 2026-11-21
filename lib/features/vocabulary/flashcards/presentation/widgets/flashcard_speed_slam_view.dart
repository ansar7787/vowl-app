import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import '../controllers/flashcard_controller.dart';
import 'flashcard_precision_strike_view.dart';
import 'flashcard_speed_fuse_bar.dart';

/// Objective arcade challenge view for Flashcard Speed Collocation Slam & Precision Strike.
class FlashcardSpeedSlamView extends StatelessWidget {
  final VocabularyQuest quest;
  final FlashcardMasteryController controller;
  final bool isDark;
  final VoidCallback onAdvanceToStage2;

  const FlashcardSpeedSlamView({
    super.key,
    required this.quest,
    required this.controller,
    required this.isDark,
    required this.onAdvanceToStage2,
  });

  @override
  Widget build(BuildContext context) {
    // Stage 1 Collocation Slam Options with defensive non-empty checks
    final collocations =
        (quest.collocations != null && quest.collocations!.isNotEmpty)
        ? quest.collocations!
        : ['authentic cuisine'];
    final wrongCollocations =
        (quest.wrongCollocations != null && quest.wrongCollocations!.isNotEmpty)
        ? quest.wrongCollocations!
        : ['authentic weather'];
    final correctCollocation = collocations.first;
    final distractorCollocation = wrongCollocations.first;

    // Balanced deterministic pairing that alternates naturally across words within each level
    final isCorrectFirst =
        (quest.id.hashCode.abs() + quest.difficulty) % 2 == 0;
    final slamOptions = isCorrectFirst
        ? [
            {'text': correctCollocation, 'isCorrect': true},
            {'text': distractorCollocation, 'isCorrect': false},
          ]
        : [
            {'text': distractorCollocation, 'isCorrect': false},
            {'text': correctCollocation, 'isCorrect': true},
          ];

    // Stage 2 Candidate Words with defensive non-empty checks
    final candidateWords = (quest.options != null && quest.options!.isNotEmpty)
        ? quest.options!
        : [
            quest.word?.toLowerCase() ?? 'authentic',
            'authoritarian',
            'automatic',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Mastery Phase Header Pill Tag ────────────────────────────────────
        Center(
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.emerald500.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🏆 MASTERY PHASE',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── High-Frequency Timer Fuse Bar with Combo Streak ──────────────
        FlashcardSpeedFuseBar(
          timerProgress: controller.timerProgress,
          comboStreak: controller.comboStreak,
          isDark: isDark,
        ),

        SizedBox(height: 16.h),

        // ── Target Word Card ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark ? AppColors.slate800 : AppColors.slate200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 14.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quest.topicEmoji != null)
                Text(quest.topicEmoji!, style: TextStyle(fontSize: 28.sp)),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  quest.word?.toUpperCase() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: isDark ? Colors.white : AppColors.slate950,
                  ),
                ),
              ),
              if (quest.definition != null) ...[
                SizedBox(height: 6.h),
                Text(
                  quest.definition!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 18.h),

        // ── Stage Switching: Stage 1 Collocation Slam vs Stage 2 Precision Strike
        ValueListenableBuilder<bool>(
          valueListenable: controller.isStage2,
          builder: (context, isStage2, _) {
            if (!isStage2) {
              return _buildStage1CollocationSlam(
                context,
                slamOptions: slamOptions,
              );
            } else {
              return FlashcardPrecisionStrikeView(
                quest: quest,
                controller: controller,
                candidateWords: candidateWords,
                isDark: isDark,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStage1CollocationSlam(
    BuildContext context, {
    required List<Map<String, Object>> slamOptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_rounded, size: 16.r, color: Colors.amber),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                'STAGE 1: CHOOSE THE NATURAL PHRASE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        ValueListenableBuilder<int?>(
          valueListenable: controller.selectedCollocationIndex,
          builder: (context, selectedIdx, _) {
            return Column(
              children: List.generate(slamOptions.length, (idx) {
                final option = slamOptions[idx];
                final text = option['text'] as String;
                final isMatchCorrect = option['isCorrect'] as bool;
                final isSelected = selectedIdx == idx;

                Color borderColor = isDark
                    ? AppColors.slate800
                    : AppColors.slate200;
                Color bgColor = isDark ? AppColors.slate900 : Colors.white;

                if (isSelected) {
                  if (isMatchCorrect) {
                    borderColor = Colors.green;
                    bgColor = Colors.green.withValues(alpha: 0.15);
                  } else {
                    borderColor = Colors.red;
                    bgColor = Colors.red.withValues(alpha: 0.15);
                  }
                }

                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: ScaleButton(
                    key: ValueKey('slam_$idx'),
                    onTap: () => controller.slamCollocation(
                      index: idx,
                      isMatchCorrect: isMatchCorrect,
                      onAdvanceToStage2: onAdvanceToStage2,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 16.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.04,
                            ),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32.r,
                            height: 32.r,
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
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              isMatchCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 20.r,
                              color: isMatchCorrect ? Colors.green : Colors.red,
                            ),
                          ],
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
