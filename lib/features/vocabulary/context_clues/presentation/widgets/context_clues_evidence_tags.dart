import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

class ContextCluesEvidenceTags extends StatelessWidget {
  final List<String> options;
  final String correct;
  final Color color;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final bool isFinalFailure;
  final Function(String) onOptionSelected;

  const ContextCluesEvidenceTags({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.isFinalFailure,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16.r,
                color: color,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  "Choose the correct word:",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: tokens?.textSecondary ?? color.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 12.w) / 2;

              return Wrap(
                spacing: 12.w,
                runSpacing: 10.h,
                children: options.map((o) {
                  final isSelected = selectedOption == o;
                  final showCorrect =
                      (isAnswered && isCorrect == true && o == correct) ||
                      (isAnswered && isFinalFailure && o == correct);
                  final showWrong =
                      isAnswered && isSelected && isCorrect == false;

                  final normalBg = isDark
                      ? (tokens?.surface ?? const Color(0xFF161822))
                      : Colors.white;
                  final normalBorder = isDark
                      ? (tokens?.borderSubtle ?? Colors.white.withValues(alpha: 0.1))
                      : color.withValues(alpha: 0.18);
                  final normalTextColor = tokens?.textPrimary ??
                      (isDark ? Colors.white : const Color(0xFF0F172A));

                  Color cardBg = normalBg;
                  Color borderColor = normalBorder;
                  Color textColor = normalTextColor;

                  if (showCorrect) {
                    final correctColor = tokens?.gameCorrect ?? Colors.green;
                    cardBg = correctColor.withValues(alpha: 0.12);
                    borderColor = correctColor;
                    textColor = correctColor;
                  } else if (showWrong) {
                    final wrongColor = tokens?.gameIncorrect ?? Colors.red;
                    cardBg = wrongColor.withValues(alpha: 0.12);
                    borderColor = wrongColor;
                    textColor = wrongColor;
                  } else if (isSelected) {
                    cardBg = color.withValues(alpha: 0.15);
                    borderColor = color;
                    textColor = color;
                  }

                  return SizedBox(
                    width: cardWidth,
                    child: ScaleButton(
                      onTap: () => onOptionSelected(o),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 13.h,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: borderColor,
                            width: (isSelected || showCorrect || showWrong)
                                ? 2.0
                                : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          o,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5.sp,
                            fontWeight: (isSelected || showCorrect)
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );

    if (reduceMotion) return content;
    return content.animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}
