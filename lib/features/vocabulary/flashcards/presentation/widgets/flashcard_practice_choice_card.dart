import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Context judgment multiple-choice card for Flashcard Practice Phase.
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
              color: isDark ? AppColors.slate800 : AppColors.slate200,
            ),
          ),
          child: Text(
            exercise.question ?? exercise.sentence ?? '',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20.h),

        // Option tiles with ScaleButton
        Column(
          children: List.generate(exercise.options.length, (index) {
            final option = exercise.options[index];
            final isSelected = selectedOptionIndex == index;
            Color borderColor = isDark
                ? AppColors.slate800
                : AppColors.slate200;
            Color tileColor = isDark ? AppColors.slate900 : Colors.white;

            if (hasChecked) {
              if (index == exercise.correctAnswerIndex) {
                borderColor = Colors.green;
                tileColor = Colors.green.withValues(alpha: 0.1);
              } else if (isSelected && !isAnswerCorrect) {
                borderColor = Colors.red;
                tileColor = Colors.red.withValues(alpha: 0.1);
              }
            } else if (isSelected) {
              borderColor = Colors.amber.shade600;
              tileColor = Colors.amber.withValues(alpha: 0.1);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
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
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.amber.shade600
                              : (isDark
                                    ? AppColors.slate800
                                    : AppColors.slate100),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w800,
                              fontSize: 12.sp,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.slate400
                                        : AppColors.slate600),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
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
