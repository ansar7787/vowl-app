import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class VowelDistinctionSpectralSlider extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final double sliderValue;
  final Function(int, int) onSubmitChoice;
  final Function(double, int) onSliderUpdate;
  final Function(double, int)? onSliderEnd;

  const VowelDistinctionSpectralSlider({
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
    this.onSliderEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('vowel_distinction_spectral_slider'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildVowelOrb(context, options[0], 0, correctIndex, color, isDark),
            _buildVowelOrb(context, options[1], 1, correctIndex, color, isDark),
          ],
        ),
        SizedBox(height: 28.h),
        _buildSliderBar(correctIndex, color),
      ],
    );
  }

  Widget _buildVowelOrb(
    BuildContext context,
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color orbColor = color.withValues(alpha: 0.08);
    Color textColor = color;
    if (isAnswered && isSelected) {
      orbColor = correct
          ? AppColors.gameCorrect.withValues(alpha: 0.2)
          : AppColors.gameIncorrect.withValues(alpha: 0.2);
      textColor = correct ? AppColors.gameCorrect : AppColors.gameIncorrect;
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
    }

    final orbWidget = Container(
      width: 96.r,
      height: 96.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: orbColor,
        border: Border.all(
          color: isAnswered && isSelected
              ? textColor
              : color.withValues(alpha: isSelected ? 1.0 : 0.3),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? (correct
                      ? AppColors.gameCorrect.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.25))
                : Colors.transparent,
            blurRadius: 14,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Option ${index + 1}: $text',
      button: true,
      selected: isSelected,
      child: ScaleButton(
        key: ValueKey('vowel_orb_$index'),
        onTap: isAnswered ? () {} : () => onSubmitChoice(index, correctIndex),
        child: reduceMotion
            ? orbWidget
            : orbWidget
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: (2 + index).seconds,
                ),
      ),
    );
  }

  Widget _buildSliderBar(int correct, Color color) {
    return Semantics(
      label:
          'Slider to select vowel. Slide left for ${options[0]}, right for ${options[1]}',
      slider: true,
      value: (sliderValue * 100).round().toString(),
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.15),
          thumbColor: color,
          overlayColor: color.withValues(alpha: 0.2),
          trackHeight: 8.h,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14.r),
        ),
        child: Slider(
          key: const ValueKey('vowel_spectral_slider'),
          value: sliderValue,
          onChanged: isAnswered ? null : (v) => onSliderUpdate(v, correctIndex),
          onChangeEnd: isAnswered
              ? null
              : (v) {
                  if (onSliderEnd != null) {
                    onSliderEnd!(v, correctIndex);
                  }
                },
        ),
      ),
    );
  }
}
