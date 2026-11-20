import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Glowing character slots displaying the learner's assembled answer word.
class FlashcardPracticeRuneSlots extends StatelessWidget {
  final String targetWord;
  final String currentText;
  final bool hasChecked;
  final bool isAnswerCorrect;
  final bool isDark;

  const FlashcardPracticeRuneSlots({
    super.key,
    required this.targetWord,
    required this.currentText,
    required this.hasChecked,
    required this.isAnswerCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color slotBorderColor = isDark
        ? AppColors.indigo500.withValues(alpha: 0.4)
        : AppColors.indigo500.withValues(alpha: 0.3);
    Color slotBgColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.5)
        : AppColors.slate100;

    if (hasChecked) {
      if (isAnswerCorrect) {
        slotBorderColor = Colors.green;
        slotBgColor = Colors.green.withValues(alpha: 0.12);
      } else {
        slotBorderColor = Colors.red;
        slotBgColor = Colors.red.withValues(alpha: 0.12);
      }
    }

    final targetChars = targetWord.split('');
    final currentChars = currentText.replaceAll(' ', '').split('');

    int nonSpaceIndex = 0;

    return Center(
      child: Wrap(
        spacing: 6.w,
        runSpacing: 8.h,
        alignment: WrapAlignment.center,
        children: List.generate(targetChars.length, (idx) {
          final char = targetChars[idx];
          if (char == ' ') {
            return SizedBox(width: 12.w);
          }

          final filledLetter = nonSpaceIndex < currentChars.length
              ? currentChars[nonSpaceIndex]
              : '';
          nonSpaceIndex++;

          final isFilled = filledLetter.isNotEmpty;

          return Container(
            width: 38.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: isFilled
                  ? (isDark ? AppColors.slate800 : Colors.white)
                  : slotBgColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isFilled
                    ? slotBorderColor
                    : slotBorderColor.withValues(alpha: 0.4),
                width: isFilled ? 2.0 : 1.2,
              ),
            ),
            child: Center(
              child: Text(
                filledLetter,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
