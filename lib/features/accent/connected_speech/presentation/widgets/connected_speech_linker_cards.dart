import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConnectedSpeechLinkerCards extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onSubmitChoice;
  final bool isCompact;

  const ConnectedSpeechLinkerCards({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onSubmitChoice,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildLinkerCard(options[0], 0)),
            SizedBox(width: 16.w),
            Expanded(child: _buildLinkerCard(options[1], 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkerCard(String text, int index) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    Color cardColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.8);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    IconData icon = Icons.linear_scale_rounded;

    if (showResult) {
      cardColor = correct
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFFE11D48).withValues(alpha: 0.15);
      borderColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      textColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      icon = correct ? Icons.link_rounded : Icons.link_off_rounded;
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = color;
      icon = Icons.link_rounded;
    }

    return ScaleButton(
          onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: isCompact ? 80.h : 110.h,
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: isCompact ? 6.h : 12.h,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black12,
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                if (showResult)
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: textColor.withValues(alpha: 0.8),
                  size: isCompact ? 18.r : 24.r,
                ),
                SizedBox(height: isCompact ? 4.h : 8.h),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 12.sp : 14.sp,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 * index).ms)
        .slideX(begin: index == 0 ? -0.1 : 0.1);
  }
}
