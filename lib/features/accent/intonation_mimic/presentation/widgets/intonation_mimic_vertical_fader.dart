import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Vertical pitch fader slider allowing learners to manually modulate pitch elevation.
class IntonationMimicVerticalFader extends StatelessWidget {
  /// Option labels for intonation states.
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

  /// Normalized vertical slider thumb height (0.0 to 1.0).
  final double sliderValue;

  /// Index associated with the highest pitch register.
  final int topIndex;

  /// Index associated with the lowest pitch register.
  final int bottomIndex;

  /// Callback executed when an option choice is finalized.
  final Function(int, int) onSubmitChoice;

  /// Callback executed while moving the fader slider.
  final Function(double, int) onSliderUpdate;

  /// Creates an [IntonationMimicVerticalFader] widget.
  const IntonationMimicVerticalFader({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.sliderValue,
    required this.topIndex,
    required this.bottomIndex,
    required this.onSubmitChoice,
    required this.onSliderUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.16),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPitchOption(
                  options[topIndex],
                  topIndex,
                  Icons.arrow_upward_rounded,
                  reduceMotion,
                ),
                SizedBox(height: 12.h),
                _buildPitchOption(
                  options[bottomIndex],
                  bottomIndex,
                  Icons.arrow_downward_rounded,
                  reduceMotion,
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          _buildVerticalSliderBar(correctIndex, color, reduceMotion),
        ],
      ),
    );
  }

  Widget _buildPitchOption(
    String text,
    int index,
    IconData iconData,
    bool reduceMotion,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    Color cardColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.9);
    Color borderColor = color.withValues(alpha: 0.25);
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (showResult) {
      cardColor = correct
          ? AppColors.emerald500.withValues(alpha: 0.15)
          : AppColors.rose700.withValues(alpha: 0.15);
      borderColor = correct ? AppColors.emerald500 : AppColors.rose700;
      textColor = correct ? AppColors.emerald500 : AppColors.rose700;
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.18);
      borderColor = color;
      textColor = color;
    }

    Widget optionCard = ScaleButton(
      key: ValueKey('intonation_option_$index'),
      onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.2),
          boxShadow: [
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(iconData, color: textColor.withValues(alpha: 0.85), size: 22.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      optionCard = optionCard
          .animate()
          .fadeIn(delay: (100 * index).ms)
          .slideX(begin: -0.1);
    }

    return optionCard;
  }

  Widget _buildVerticalSliderBar(
    int correct,
    Color color,
    bool reduceMotion,
  ) {
    Widget sliderBar = Container(
      height: 136.h,
      width: 50.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.transparent,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 18.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14.r),
          ),
          child: IgnorePointer(
            ignoring: isAnswered,
            child: Semantics(
              slider: true,
              value: sliderValue >= 0.5
                  ? options[topIndex]
                  : options[bottomIndex],
              increasedValue: options[topIndex],
              decreasedValue: options[bottomIndex],
              child: Slider(
                key: const ValueKey('intonation_slider'),
                value: sliderValue,
                onChanged: (v) => onSliderUpdate(v, correct),
              ),
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      sliderBar = sliderBar
          .animate()
          .fadeIn(delay: 200.ms)
          .slideY(begin: 0.2);
    }

    return sliderBar;
  }
}
