import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Dialogue balloon list presenting conversational response options in shadowing exercises.
class ShadowingChallengeDialogueList extends StatelessWidget {
  /// Available dialogue options.
  final List<String> options;

  /// Index of the correct option.
  final int correctIndex;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Selected option index, or `null`.
  final int? selectedIndex;

  /// Callback executed when the learner selects a dialogue option.
  final Function(int, int) onSubmitChoice;

  /// Creates a [ShadowingChallengeDialogueList] widget.
  const ShadowingChallengeDialogueList({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onSubmitChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildDialogueBubble(options[index], index),
        );
      }),
    );
  }

  Widget _buildDialogueBubble(String text, int index) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    Color bubbleColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.7)
        : AppColors.white;
    Color borderColor = isDark ? AppColors.slate700 : AppColors.slate200;
    Color textColor = isDark ? AppColors.slate100 : AppColors.slate900;
    Color iconColor = isDark ? AppColors.slate400 : AppColors.slate500;
    IconData iconData = Icons.chat_bubble_outline_rounded;

    if (showResult) {
      final feedbackColor = correct ? AppColors.emerald500 : AppColors.rose700;
      bubbleColor = feedbackColor.withValues(alpha: 0.12);
      borderColor = feedbackColor;
      textColor = feedbackColor;
      iconColor = feedbackColor;
      iconData = correct
          ? Icons.check_circle_outline_rounded
          : Icons.cancel_outlined;
    } else if (isSelected) {
      bubbleColor = color.withValues(alpha: 0.1);
      borderColor = color;
      textColor = color;
      iconColor = color;
      iconData = Icons.record_voice_over_rounded;
    }

    return ScaleButton(
      key: ValueKey('shadowing_option_$index'),
      onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: isSelected || showResult ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected && !showResult)
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (120 * index).ms).slideY(begin: 0.15);
  }
}
