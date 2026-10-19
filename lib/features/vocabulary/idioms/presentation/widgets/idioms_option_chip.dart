import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

class IdiomsOptionChip extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final VoidCallback onTap;

  const IdiomsOptionChip({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedOption == text;
    final isWrong = isAnswered && isSelected && isCorrect == false;
    final isCorrectOption = isAnswered && text == correct && isCorrect == true;

    Color cardBg = isDark ? color.withValues(alpha: 0.08) : Colors.white;
    Color cardBorder = isDark ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.2);
    Color textColor = isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.slate900;

    if (isCorrectOption) {
      cardBg = AppColors.gameCorrect.withValues(alpha: isDark ? 0.2 : 0.12);
      cardBorder = AppColors.gameCorrect;
      textColor = isDark ? Colors.white : AppColors.gameCorrect;
    } else if (isWrong) {
      cardBg = AppColors.gameIncorrect.withValues(alpha: isDark ? 0.2 : 0.12);
      cardBorder = AppColors.gameIncorrect;
      textColor = isDark ? Colors.white : AppColors.gameIncorrect;
    } else if (isSelected) {
      cardBg = color.withValues(alpha: isDark ? 0.25 : 0.15);
      cardBorder = color;
      textColor = isDark ? Colors.white : color;
    }

    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cardBorder, width: 1.2),
          boxShadow: [
            if (isSelected || isCorrectOption)
              BoxShadow(
                color: cardBorder.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.8.sw),
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.4,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}
