import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
class CollocationOptionBubble extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final bool isFinalFailure;
  final int index;
  final VoidCallback onTap;

  const CollocationOptionBubble({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.isFinalFailure,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedOption == text;
    final showCorrect =
        (isAnswered && isCorrect == true && text == correct) ||
        (isAnswered && isFinalFailure && text == correct);
    final showWrong = isAnswered && isSelected && isCorrect == false;

    Color bubbleColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (showCorrect) {
      bubbleColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (showWrong) {
      bubbleColor = Colors.red.withValues(alpha: 0.2);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else if (isSelected) {
      bubbleColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = color;
    }

    Widget bubble = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 130.w,
        height: 130.w,
        decoration: BoxDecoration(
          color: bubbleColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: isSelected || showCorrect || showWrong ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: showCorrect || isSelected
                  ? borderColor.withValues(alpha: 0.3)
                  : Colors.transparent,
              blurRadius: showCorrect || isSelected ? 15 : 0,
              spreadRadius: showCorrect || isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(15.r),
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );

    // Apply the "Selected" bump
    Widget animatedBubble = bubble
        .animate(target: isSelected && !showCorrect ? 1 : 0)
        .scale(end: const Offset(1.05, 1.05), duration: 200.ms);

    // Apply the massive "Pop Fusion" explosion if correct
    animatedBubble = animatedBubble
        .animate(target: showCorrect ? 1 : 0)
        .scale(
          end: const Offset(1.8, 1.8),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .fadeOut(duration: 500.ms);

    // Apply the staggered responsive vertical offset and continuous floating
    double staggeredOffset = index % 2 == 0 ? -15.h : 15.h;

    return Transform.translate(
      offset: Offset(0, staggeredOffset),
      child: animatedBubble
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -6,
            end: 6,
            duration: (1500 + (index * 300)).ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
