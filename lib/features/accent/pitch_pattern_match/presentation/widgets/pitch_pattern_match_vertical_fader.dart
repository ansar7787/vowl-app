import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PitchPatternMatchVerticalFader extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final double sliderValue;
  final Function(int, int) onSubmitChoice;
  final Function(double, int) onSliderUpdate;

  const PitchPatternMatchVerticalFader({
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (options.isNotEmpty)
                _buildPitchOption(options[0], 0, Icons.arrow_upward_rounded),
              if (options.length > 1) ...[
                SizedBox(height: 14.h),
                _buildPitchOption(options[1], 1, Icons.arrow_downward_rounded),
              ],
            ],
          ),
        ),
        SizedBox(width: 20.w),
        _buildVerticalSliderBar(correctIndex, color),
      ],
    );
  }

  Widget _buildPitchOption(String text, int index, IconData iconData) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    Color cardColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.75)
        : Colors.white;
    Color borderColor = color.withValues(alpha: isDark ? 0.25 : 0.18);
    Color textColor = isDark ? Colors.white : AppColors.slate800;

    if (showResult) {
      cardColor = correct
          ? AppColors.emerald500.withValues(alpha: 0.15)
          : AppColors.rose700.withValues(alpha: 0.15);
      borderColor = correct ? AppColors.emerald500 : AppColors.rose700;
      textColor = correct ? AppColors.emerald500 : AppColors.rose700;
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.15);
      borderColor = color;
      textColor = color;
    }

    return ScaleButton(
      key: ValueKey('pitch_pattern_option_$index'),
      onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: showResult
                  ? borderColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: showResult ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: (isSelected || showResult)
                    ? textColor.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : color.withValues(alpha: 0.08)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: textColor,
                size: 20.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.35,
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
      height: 140.h,
      width: 52.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(26.r),
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
            trackHeight: 20.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15.r),
          ),
          child: IgnorePointer(
            ignoring: isAnswered,
            child: Slider(
              key: const ValueKey('pitch_pattern_slider'),
              value: sliderValue,
              onChanged: (v) => onSliderUpdate(v, correct),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
