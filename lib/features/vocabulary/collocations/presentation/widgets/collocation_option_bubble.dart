import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Circular interactive bubble representing candidate collocate choices with floating and explosion animations.
class CollocationOptionBubble extends StatelessWidget {
  /// Candidate collocate word string.
  final String text;

  /// The correct collocate partner string.
  final String correct;

  /// Theme accent color for bubble borders and glow highlights.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Whether the quest trial has been answered.
  final bool isAnswered;

  /// Whether the user's selected choice was correct, or `null` if unanswered.
  final bool? isCorrect;

  /// Currently selected option string, if any.
  final String? selectedOption;

  /// Whether the trial has concluded in a final failure.
  final bool isFinalFailure;

  /// Whether stage 1 (collocate identification) has been successfully passed.
  final bool isFirstStagePassed;

  /// Whether the user has activated a hint for this question.
  final bool isHintUsed;

  /// Position index of this option bubble for staggered floating effects.
  final int index;

  /// Whether compact geometry is enforced for small devices.
  final bool isCompact;

  /// Callback executed when the user taps this option bubble.
  final VoidCallback onTap;

  /// Creates a [CollocationOptionBubble] widget.
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
    required this.isFirstStagePassed,
    this.isHintUsed = false,
    required this.index,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isSelected = selectedOption == text;
    final isPhase1Correct = isFirstStagePassed && isSelected;
    final isExploding =
        (isAnswered && isCorrect == true && text == correct) ||
        (isAnswered && isFinalFailure && text == correct) ||
        isPhase1Correct;
    final isGlowingHint = isHintUsed && text == correct && !isFirstStagePassed;
    final showCorrect = isExploding || isGlowingHint;
    final showWrong =
        isAnswered && isSelected && isCorrect == false && !isPhase1Correct;

    Color bubbleColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = Theme.of(context).colorScheme.onSurface;

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
        width: isCompact ? 96.w : 118.w,
        height: isCompact ? 96.w : 118.w,
        decoration: BoxDecoration(
          color: bubbleColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: isSelected || showCorrect || showWrong ? 2.5 : 1.2,
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
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
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
        .animate(target: isExploding ? 1 : 0)
        .scale(
          end: const Offset(1.8, 1.8),
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeOut(duration: 500.ms);

    // Apply scale out for unselected options in phase 2
    final isUnselectedInPhase2 = isFirstStagePassed && !isSelected;
    animatedBubble = animatedBubble
        .animate(target: isUnselectedInPhase2 ? 1 : 0)
        .scale(
          end: const Offset(0.0, 0.0),
          duration: 300.ms,
          curve: Curves.easeIn,
        )
        .fadeOut(duration: 300.ms);

    // Apply a pulsing glow if it's a hint
    if (isGlowingHint) {
      animatedBubble = animatedBubble
          .animate(onPlay: reduceMotion ? null : (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
            curve: Curves.easeInOutSine,
          );
    }

    // Apply the staggered responsive vertical offset and continuous floating
    double staggeredOffset = index % 2 == 0 ? -15.h : 15.h;

    return Transform.translate(
      offset: Offset(0, staggeredOffset),
      child: animatedBubble
          .animate(onPlay: reduceMotion ? null : (c) => c.repeat(reverse: true))
          .moveY(
            begin: -6,
            end: 6,
            duration: (1500 + (index * 300)).ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
