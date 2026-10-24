import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Column of letter-labeled inference option cards.
class ListeningInferenceGrid extends StatelessWidget {
  /// Available deduction option strings.
  final List<String> options;

  /// Index of the correct option.
  final int correctAnswerIndex;

  /// Theme accent color.
  final Color color;

  /// Whether the answer has been locked in and evaluated.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Callback when an inference option is selected.
  final Function(int) onSubmitAnswer;

  /// Creates a [ListeningInferenceGrid] options column.
  const ListeningInferenceGrid({
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
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        final isChoiceCorrect =
            isAnswered && index == correctAnswerIndex && isCorrectState == true;
        final isChoiceWrong =
            isAnswered && isSelected && isCorrectState == false;

        Color getBgColor() {
          if (isChoiceCorrect) {
            return tokens?.gameCorrect ?? AppColors.gameCorrect;
          }
          if (isChoiceWrong) {
            return tokens?.gameIncorrect ?? AppColors.gameIncorrect;
          }
          if (isSelected) {
            return color.withValues(alpha: isDark ? 0.28 : 0.12);
          }
          return isDark ? const Color(0xFF1E293B) : Colors.white;
        }

        Color getBorderColor() {
          if (isChoiceCorrect) {
            return tokens?.gameCorrect ?? AppColors.gameCorrect;
          }
          if (isChoiceWrong) {
            return tokens?.gameIncorrect ?? AppColors.gameIncorrect;
          }
          if (isSelected) {
            return color;
          }
          return isDark
              ? color.withValues(alpha: 0.28)
              : color.withValues(alpha: 0.18);
        }

        Color getTextColor() {
          if (isChoiceCorrect || isChoiceWrong) {
            return Colors.white;
          }
          if (isSelected) {
            return isDark ? Colors.white : color;
          }
          return isDark ? Colors.white : const Color(0xFF1E293B);
        }

        final letterLabel = String.fromCharCode(65 + index);

        final cardWidget = Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Semantics(
            label: options[index],
            button: true,
            excludeSemantics: true,
            child: ScaleButton(
              key: Key('listening_inference_option_$index'),
              onTap: isAnswered ? null : () => onSubmitAnswer(index),
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
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
                      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
                      offset: Offset(0, 3.h),
                      blurRadius: 8,
                    ),
                    if (isSelected || isChoiceCorrect || isChoiceWrong)
                      BoxShadow(
                        color: (isChoiceCorrect
                                ? (tokens?.gameCorrect ?? AppColors.gameCorrect)
                                : (isChoiceWrong
                                    ? (tokens?.gameIncorrect ??
                                        AppColors.gameIncorrect)
                                    : color))
                            .withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Status / Letter indicator
                    Container(
                      width: 28.r,
                      height: 28.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isChoiceCorrect || isChoiceWrong
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isSelected
                                ? color.withValues(alpha: 0.18)
                                : color.withValues(alpha: 0.08)),
                        shape: BoxShape.circle,
                      ),
                      child: isChoiceCorrect
                          ? Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 18.r,
                            )
                          : (isChoiceWrong
                              ? Icon(
                                  Icons.report_problem_rounded,
                                  color: Colors.white,
                                  size: 18.r,
                                )
                              : Text(
                                  letterLabel,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? color : (isDark ? Colors.white70 : color),
                                  ),
                                )),
                    ),
                    SizedBox(width: 14.w),
                    // Option Text
                    Expanded(
                      child: Text(
                        options[index],
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: getTextColor(),
                          height: 1.35,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (isSelected && !isAnswered)
                      Icon(
                        Icons.radio_button_checked,
                        color: color,
                        size: 18.r,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (reduceMotion) {
          return cardWidget;
        }

        return cardWidget
            .animate(target: isChoiceWrong ? 1 : 0)
            .shake(duration: 400.ms);
      }),
    );
  }
}
