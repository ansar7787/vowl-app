import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Multiple-choice option card answering the speed reading comprehension question.
class ReadingSpeedOption extends StatelessWidget {
  /// Zero-based option index determining option letter.
  final int index;

  /// The option text content.
  final String text;

  /// The authoritative correct answer string.
  final String correct;

  /// Theme accent color applied to cards and borders.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// The currently chosen option index, or null if unselected.
  final int? selectedIndex;

  /// Whether the quest has been evaluated.
  final bool isAnswered;

  /// Callback invoked when this option is tapped.
  final VoidCallback onTap;

  /// Creates a [ReadingSpeedOption] widget.
  const ReadingSpeedOption({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool isSelected = selectedIndex == index;
    final bool isCorrect =
        isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    final bool isWrong = isAnswered && isSelected && !isCorrect;

    // Clean flat styling logic
    final Color baseColor = isCorrect
        ? tokens.gameCorrect
        : (isWrong ? tokens.gameIncorrect : color);

    final Color bgColor = isCorrect
        ? tokens.gameCorrect.withValues(alpha: 0.12)
        : (isWrong
              ? tokens.gameIncorrect.withValues(alpha: 0.12)
              : (isSelected
                    ? color.withValues(alpha: 0.1)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white)));

    final String letter = String.fromCharCode(65 + index);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: bgColor,
            border: Border.all(
              color: isSelected || isCorrect || isWrong
                  ? baseColor.withValues(alpha: 0.8)
                  : (isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.08)),
              width: isSelected || isCorrect || isWrong ? 2.w : 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28.r,
                height: 28.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected || isCorrect || isWrong
                      ? baseColor.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected || isCorrect || isWrong
                          ? baseColor
                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    height: 1.35,
                    fontWeight: isSelected || isCorrect || isWrong
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isAnswered && (isCorrect || isWrong)) ...[
                SizedBox(width: 8.w),
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: baseColor,
                  size: 20.r,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
