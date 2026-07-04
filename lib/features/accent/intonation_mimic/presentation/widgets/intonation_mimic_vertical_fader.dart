import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class IntonationMimicVerticalFader extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final double sliderValue;
  final Function(int, int) onSubmitChoice;
  final Function(double, int) onSliderUpdate;

  const IntonationMimicVerticalFader({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.sliderValue,
    required this.onSubmitChoice,
    required this.onSliderUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPitchOption(options[0], 0, Icons.arrow_upward_rounded),
              SizedBox(height: 16.h),
              _buildPitchOption(options[1], 1, Icons.arrow_downward_rounded),
            ],
          ),
        ),
        SizedBox(width: 32.w),
        _buildVerticalSliderBar(correctIndex, color),
      ],
    );
  }

  Widget _buildPitchOption(String text, int index, IconData iconData) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    Color cardColor = isDark 
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.8);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (showResult) {
      cardColor = correct
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFFE11D48).withValues(alpha: 0.15);
      borderColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      textColor = correct ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = color;
    }

    return ScaleButton(
      onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
          boxShadow: [
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
          ],
        ),
        child: Row(
          children: [
            Icon(
              iconData,
              color: textColor.withValues(alpha: 0.8),
              size: 24.r,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.1);
  }

  Widget _buildVerticalSliderBar(int correct, Color color) {
    return Container(
      height: 176.h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.transparent,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 24.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16.r),
          ),
          child: IgnorePointer(
            ignoring: isAnswered,
            child: Slider(
              value: sliderValue,
              onChanged: (v) => onSliderUpdate(v, correct),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
