import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Interactive particle key button representing a preposition or adverb candidate to complete the phrasal verb.
class PhrasalVerbsOptionKey extends StatelessWidget {
  /// Particle text string rendered on the key.
  final String text;

  /// The correct particle expected to unlock the vault.
  final String correct;

  /// Theme accent color for key borders and active highlights.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Whether the user has answered the trial.
  final bool isAnswered;

  /// Whether the selected option was correct, or `null` if pending.
  final bool? isCorrect;

  /// Currently selected particle option string.
  final String? selectedOption;

  /// Whether all lives or retry attempts have been exhausted.
  final bool isFinalFailure;

  /// Whether the user requested a hint for this question.
  final bool isHintUsed;

  /// Position index of this key card.
  final int index;

  /// Callback executed when the key is tapped.
  final VoidCallback onTap;

  /// Creates a [PhrasalVerbsOptionKey] widget.
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
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isSelected = selectedOption == text;
    final isExploding =
        (isAnswered && isCorrect == true && text == correct) ||
        (isAnswered && isFinalFailure && text == correct);
    final isGlowingHint = isHintUsed && text == correct && !isAnswered;
    final showCorrect = isExploding || isGlowingHint;
    final isWrong = isAnswered && isSelected && isCorrect == false;

    Color cardBg = isDark ? color.withValues(alpha: 0.08) : Colors.white;
    Color cardBorder = color.withValues(alpha: isDark ? 0.25 : 0.2);
    Color textColor = Theme.of(context).colorScheme.onSurface;

    if (showCorrect) {
      cardBg = tokens.gameCorrect;
      cardBorder = tokens.gameCorrect;
      textColor = Colors.white;
    } else if (isWrong) {
      cardBg = tokens.gameIncorrect;
      cardBorder = tokens.gameIncorrect;
      textColor = Colors.white;
    } else if (isSelected) {
      cardBg = color;
      cardBorder = color;
      textColor = Colors.white;
    }

    Widget keyCard = ScaleButton(
      onTap: onTap,
      child: Container(
        width: 148.w,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: showCorrect
                  ? tokens.gameCorrect.withValues(alpha: 0.4)
                  : (isWrong
                        ? tokens.gameIncorrect.withValues(alpha: 0.4)
                        : (isSelected
                              ? color.withValues(alpha: 0.3)
                              : (isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : color.withValues(alpha: 0.06)))),
              blurRadius: showCorrect || isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AutoSizeText(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 12,
            stepGranularity: 0.5,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );

    if (isExploding) {
      keyCard = keyCard.animate().scale(
        end: const Offset(1.08, 1.08),
        duration: 300.ms,
        curve: Curves.easeOutCubic,
      );
    } else if (isWrong) {
      keyCard = keyCard.animate().shakeX(amount: 5, duration: 400.ms);
    } else if (isGlowingHint) {
      keyCard = keyCard
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
            curve: Curves.easeInOutSine,
          );
    }

    return keyCard;
  }
}
