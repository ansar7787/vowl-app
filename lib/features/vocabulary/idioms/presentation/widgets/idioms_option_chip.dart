import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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

    Color cardBg = isDark ? color.withValues(alpha: 0.1) : Colors.white;
    Color cardBorder = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (isCorrectOption) {
      cardBg = Colors.green.withValues(alpha: 0.2);
      cardBorder = Colors.green;
      textColor = isDark ? Colors.white : Colors.green.shade700;
    } else if (isWrong) {
      cardBg = Colors.red.withValues(alpha: 0.2);
      cardBorder = Colors.red;
      textColor = isDark ? Colors.white : Colors.red.shade700;
    } else if (isSelected) {
      cardBg = color.withValues(alpha: 0.3);
      cardBorder = color;
      textColor = isDark ? Colors.white : color;
    }

    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: cardBorder, width: 1.5),
          boxShadow: [
            if (isSelected || isCorrectOption)
              BoxShadow(
                color: cardBorder.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
