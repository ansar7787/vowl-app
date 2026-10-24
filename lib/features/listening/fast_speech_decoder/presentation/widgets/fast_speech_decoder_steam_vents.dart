import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// List of sentence options displayed as steam vents for answer selection.
class FastSpeechDecoderSteamVents extends StatelessWidget {
  /// Available sentence transcript options.
  final List<String> options;

  /// Index of the correct transcription.
  final int correctAnswerIndex;

  /// Theme accent color.
  final Color color;

  /// Whether the answer has been locked in and evaluated.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Callback when an option is selected.
  final Function(int) onSubmitAnswer;

  /// Creates a [FastSpeechDecoderSteamVents] options list.
  const FastSpeechDecoderSteamVents({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        final isChoiceCorrect =
            isAnswered && index == correctAnswerIndex && isCorrectState == true;
        final isChoiceWrong =
            isAnswered && isSelected && isCorrectState == false;

        Color getBgColor() {
          if (isChoiceCorrect) return tokens.gameCorrect;
          if (isChoiceWrong) return tokens.gameIncorrect;
          if (isSelected) return color;
          return isDark ? tokens.surface : Colors.white;
        }

        Color getBorderColor() {
          if (isChoiceCorrect) return tokens.gameCorrect;
          if (isChoiceWrong) return tokens.gameIncorrect;
          if (isSelected) return color;
          return isDark
              ? color.withValues(alpha: 0.3)
              : tokens.border;
        }

        Color getTextColor() {
          if (isChoiceCorrect || isChoiceWrong || isSelected) {
            return Colors.white;
          }
          return isDark ? Colors.white : tokens.textPrimary;
        }

        Color getIconColor() {
          if (isChoiceCorrect || isChoiceWrong || isSelected) {
            return Colors.white;
          }
          return isDark
              ? color.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.7);
        }

        IconData getIconData() {
          if (isChoiceCorrect) return Icons.verified_rounded;
          if (isChoiceWrong) return Icons.error_outline_rounded;
          if (isSelected) return Icons.radio_button_checked_rounded;
          return Icons.radio_button_unchecked_rounded;
        }

        final ventWidget = Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Semantics(
            label: options[index],
            button: true,
            excludeSemantics: true,
            child: ScaleButton(
              key: Key('fast_speech_decoder_vent_$index'),
              onTap: () => onSubmitAnswer(index),
              child: Container(
                constraints: BoxConstraints(minHeight: 56.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: getBgColor(),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: getBorderColor(),
                    width: isSelected || isChoiceCorrect || isChoiceWrong ? 2.0 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      offset: Offset(0, 3.h),
                      blurRadius: 8,
                    ),
                    if (isSelected || isChoiceCorrect || isChoiceWrong)
                      BoxShadow(
                        color: getBgColor().withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: Offset(0, 4.h),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      getIconData(),
                      color: getIconColor(),
                      size: 20.r,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        options[index],
                        textAlign: TextAlign.start,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.5.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: getTextColor(),
                          height: 1.35,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (reduceMotion) {
          return ventWidget;
        }

        return ventWidget
            .animate(target: isChoiceWrong ? 1 : 0)
            .shake(duration: 400.ms);
      }),
    );
  }
}
