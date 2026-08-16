import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PhrasalVerbsOptionKey extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final bool isFinalFailure;
  final bool isHintUsed;
  final int index;
  final VoidCallback onTap;

  const PhrasalVerbsOptionKey({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.isFinalFailure,
    this.isHintUsed = false,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedOption == text;
    final isExploding =
        (isAnswered && isCorrect == true && text == correct) ||
        (isAnswered && isFinalFailure && text == correct);
    final isGlowingHint = isHintUsed && text == correct && !isAnswered;
    final showCorrect = isExploding || isGlowingHint;
    final isWrong = isAnswered && isSelected && isCorrect == false;

    Color cardBg = isDark ? color.withValues(alpha: 0.1) : Colors.white;
    Color cardBorder = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (showCorrect) {
      cardBg = Colors.green;
      cardBorder = Colors.greenAccent;
      textColor = Colors.white;
    } else if (isWrong) {
      cardBg = Colors.red;
      cardBorder = Colors.redAccent;
      textColor = Colors.white;
    } else if (isSelected) {
      cardBg = color;
      cardBorder = color;
      textColor = Colors.white;
    }

    Widget keyCard = ScaleButton(
      onTap: onTap,
      child: Container(
        width: 150.w,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: cardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: showCorrect
                  ? Colors.green.withValues(alpha: 0.5)
                  : (isWrong
                        ? Colors.red.withValues(alpha: 0.5)
                        : color.withValues(alpha: 0.1)),
              blurRadius: showCorrect || isSelected ? 15 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );

    if (isExploding) {
      keyCard = keyCard.animate().scale(
        end: const Offset(1.1, 1.1),
        duration: 300.ms,
        curve: Curves.easeOutBack,
      );
    } else if (isWrong) {
      keyCard = keyCard.animate().shakeX(amount: 5, duration: 400.ms);
    } else if (isGlowingHint) {
      keyCard = keyCard.animate(onPlay: (c) => c.repeat(reverse: true)).scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: 800.ms,
        curve: Curves.easeInOutSine,
      );
    }

    return keyCard
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: -3.h,
          end: 3.h,
          duration: (1200 + (index * 200)).ms,
          curve: Curves.easeInOut,
        );
  }
}
