import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Choice Battle Crystals card for the Flashcard Practice Phase.
///
/// Features glowing crystal badge indicators, high-contrast options,
/// scale-spring taps, and animated evaluation states.
class FlashcardPracticeChoiceCard extends StatelessWidget {
  final PracticeExercise exercise;
  final int? selectedOptionIndex;
  final bool hasChecked;
  final bool isAnswerCorrect;
  final bool isDark;
  final ValueChanged<int> onSelectOption;

  const FlashcardPracticeChoiceCard({
    super.key,
    required this.exercise,
    required this.selectedOptionIndex,
    required this.hasChecked,
    required this.isAnswerCorrect,
    required this.isDark,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question / Prompt Container
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: isDark ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.amber.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.08),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Text(
            exercise.question ?? exercise.sentence ?? '',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20.h),

        // Crystal Option Tiles with ScaleButton
        Column(
          children: List.generate(exercise.options.length, (index) {
            final option = exercise.options[index];
            final isSelected = selectedOptionIndex == index;
            Color borderColor = isDark
                ? AppColors.slate800
                : AppColors.slate200;
            Color tileColor = isDark ? AppColors.slate900 : Colors.white;
            Color badgeBgColor = isDark
                ? AppColors.slate800
                : AppColors.slate100;
            Color badgeTextColor = isDark
                ? AppColors.slate400
                : AppColors.slate600;

            if (hasChecked) {
              if (index == exercise.correctAnswerIndex) {
                borderColor = Colors.green;
                tileColor = Colors.green.withValues(alpha: 0.12);
                badgeBgColor = Colors.green;
                badgeTextColor = Colors.white;
              } else if (isSelected && !isAnswerCorrect) {
                borderColor = Colors.red;
                tileColor = Colors.red.withValues(alpha: 0.12);
                badgeBgColor = Colors.red;
                badgeTextColor = Colors.white;
              }
            } else if (isSelected) {
              borderColor = Colors.amber.shade600;
              tileColor = Colors.amber.withValues(alpha: 0.10);
              badgeBgColor = Colors.amber.shade600;
              badgeTextColor = Colors.white;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: ScaleButton(
                onTap: hasChecked ? null : () => onSelectOption(index),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeBgColor,
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              color: badgeTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.slate900,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (hasChecked &&
                          index == exercise.correctAnswerIndex) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 20.r,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
