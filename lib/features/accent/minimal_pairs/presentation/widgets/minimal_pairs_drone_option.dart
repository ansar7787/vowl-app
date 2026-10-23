import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Interactive drone target card representing a single minimal pair phonetic choice.
class MinimalPairsDroneOption extends StatelessWidget {
  /// Option index.
  final int index;

  /// Written word representation.
  final String word;

  /// International Phonetic Alphabet (IPA) representation.
  final String ipa;

  /// Index of the correct minimal pair option.
  final int correctIndex;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Selected drone option index, or `null`.
  final int? selectedDroneIndex;

  /// Callback executed when the learner shoots/selects this drone target.
  final Function(int, int) onShoot;

  /// Explicit card width constraint override.
  final double? cardWidth;

  /// Explicit card height constraint override.
  final double? cardHeight;

  /// Creates a [MinimalPairsDroneOption] widget.
  const MinimalPairsDroneOption({
    super.key,
    required this.index,
    required this.word,
    required this.ipa,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedDroneIndex,
    required this.onShoot,
    this.cardWidth,
    this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final bool isSelected = selectedDroneIndex == index;
    final bool correct = index == correctIndex;

    Color borderColor = color.withValues(alpha: isDark ? 0.35 : 0.25);
    Color cardBg = isDark ? const Color(0xFF1E2230) : Colors.white;

    if (isAnswered && isSelected) {
      borderColor = correct ? tokens.gameCorrect : tokens.gameIncorrect;
      cardBg = isDark
          ? (correct
              ? tokens.gameCorrect.withValues(alpha: 0.15)
              : tokens.gameIncorrect.withValues(alpha: 0.15))
          : (correct
              ? tokens.gameCorrect.withValues(alpha: 0.08)
              : tokens.gameIncorrect.withValues(alpha: 0.08));
    } else if (isSelected) {
      borderColor = color;
    }

    final String semanticLabel = isAnswered && isSelected
        ? "$word, ${correct ? context.tr('games.correct', fallback: 'Correct!') : context.tr('games.incorrect', fallback: 'Incorrect!')}"
        : word;

    final effectiveWidth = cardWidth ?? 136.w;
    final effectiveHeight = cardHeight ?? 112.h;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isAnswered,
      excludeSemantics: true,
      child: ScaleButton(
        key: ValueKey('minimal_pairs_drone_$index'),
        onTap: () => onShoot(index, correctIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                Widget card = AnimatedContainer(
                  duration: 250.milliseconds,
                  width: effectiveWidth,
                  height: effectiveHeight,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected && isAnswered)
                            ? (correct
                                ? tokens.gameCorrect.withValues(alpha: 0.25)
                                : tokens.gameIncorrect.withValues(alpha: 0.25))
                            : (isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : color.withValues(alpha: 0.08)),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                word.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 19.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: isDark ? 0.15 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ipa,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (!reduceMotion) {
                  card = card
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: 0,
                        end: index == 0 ? 5.h : -5.h,
                        duration: (2 + index).seconds,
                      );
                }

                return card;
              },
            ),
            SizedBox(height: 8.h),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: (isAnswered && isSelected) ? 1.0 : 0.0,
              child: Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: correct ? tokens.gameCorrect : tokens.gameIncorrect,
                size: 22.r,
              ).animate(target: (isAnswered && isSelected) ? 1 : 0).scale(),
            ),
          ],
        ),
      ),
    );
  }
}
