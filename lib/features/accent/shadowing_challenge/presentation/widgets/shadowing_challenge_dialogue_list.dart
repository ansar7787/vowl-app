import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ShadowingChallengeDialogueList extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onSubmitChoice;

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
          padding: EdgeInsets.only(bottom: 16.h),
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
        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.7);
    Color borderColor = color.withValues(alpha: 0.2);
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    IconData iconData = Icons.chat_bubble_outline_rounded;

    if (showResult) {
      bubbleColor = correct
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFFE11D48).withValues(alpha: 0.15);
      borderColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      textColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      iconData = correct
          ? Icons.check_circle_outline_rounded
          : Icons.cancel_outlined;
    } else if (isSelected) {
      bubbleColor = color.withValues(alpha: 0.15);
      borderColor = color;
      textColor = color;
      iconData = Icons.record_voice_over_rounded;
    }

    return ScaleButton(
      onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
            bottomLeft: Radius.circular(index % 2 == 0 ? 8.r : 24.r),
            bottomRight: Radius.circular(index % 2 == 0 ? 24.r : 8.r),
          ),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black12,
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(iconData, color: textColor.withValues(alpha: 0.8), size: 24.r),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (150 * index).ms).slideY(begin: 0.2);
  }
}
