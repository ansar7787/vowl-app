import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive orbiting satellite option card for multiple-choice listening challenges.
class AudioMultipleChoiceSatellite extends StatelessWidget {
  /// Zero-based index of this satellite node among options.
  final int index;

  /// Option label text.
  final String text;

  /// Zero-based index of the correct answer.
  final int correct;

  /// Theme accent color.
  final Color color;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Whether the question has been answered.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Callback triggered when this satellite option is selected.
  final VoidCallback onTap;

  /// Creates an [AudioMultipleChoiceSatellite] instance.
  const AudioMultipleChoiceSatellite({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrectState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isSelected = selectedIndex == index;
    final isCorrect = isAnswered && index == correct && isCorrectState == true;
    final isWrong = isAnswered && isSelected && isCorrectState == false;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color getBgColor() {
      if (isCorrect) return tokens.gameCorrect;
      if (isWrong) return tokens.gameIncorrect;
      if (isSelected) return color;
      return isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    }

    Color getBorderColor() {
      if (isCorrect) return tokens.gameCorrect;
      if (isWrong) return tokens.gameIncorrect;
      if (isSelected) return color;
      return isDark
          ? color.withValues(alpha: 0.3)
          : color.withValues(alpha: 0.2);
    }

    Color getTextColor() {
      if (isCorrect || isWrong || isSelected) return Colors.white;
      return isDark ? Colors.white : const Color(0xFF1E293B);
    }

    final cardWidth = isSelected ? 136.w : 128.w;
    final cardMinHeight = isSelected ? 62.h : 56.h;
    final cardMaxHeight = isSelected ? 80.h : 74.h;

    final button = ScaleButton(
      key: Key('satellite_option_$index'),
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : 250.ms,
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minWidth: isSelected ? 92.w : 84.w,
          maxWidth: cardWidth,
          minHeight: cardMinHeight,
          maxHeight: cardMaxHeight,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: getBorderColor(),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: getBgColor().withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: cardWidth - 18.w,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isSelected ? 13.5.sp : 12.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: getTextColor(),
                  height: 1.25,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return button;
    }

    return button
        .animate()
        .fadeIn(duration: 400.ms, delay: (100 * index).ms)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: (100 * index).ms,
          curve: Curves.easeOutCubic,
        );
  }
}
