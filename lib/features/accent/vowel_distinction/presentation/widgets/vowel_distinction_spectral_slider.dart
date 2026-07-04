import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildVowelOrb(options[0], 0, correctIndex, color, isDark),
            _buildVowelOrb(options[1], 1, correctIndex, color, isDark),
          ],
        ),
        SizedBox(height: 32.h),
        _buildSliderBar(correctIndex, color),
      ],
    );
  }

  Widget _buildVowelOrb(
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;

    Color orbColor = color.withValues(alpha: 0.1);
    Color textColor = color;
    if (isAnswered && isSelected) {
      orbColor = correct
          ? Colors.greenAccent.withValues(alpha: 0.2)
          : Colors.redAccent.withValues(alpha: 0.2);
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
    }

    return ScaleButton(
      onTap: () => onSubmitChoice(index, correctIndex),
      child:
          Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orbColor,
                  border: Border.all(
                    color: isAnswered && isSelected
                        ? textColor
                        : color.withValues(alpha: isSelected ? 1.0 : 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? (correct
                                ? Colors.greenAccent.withValues(alpha: 0.3)
                                : color.withValues(alpha: 0.3))
                          : Colors.transparent,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: (2 + index).seconds,
              ),
    );
  }

  Widget _buildSliderBar(int correct, Color color) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: color,
        inactiveTrackColor: color.withValues(alpha: 0.1),
        thumbColor: color,
        overlayColor: color.withValues(alpha: 0.2),
        trackHeight: 10.h,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16.r),
      ),
      child: Slider(
        value: sliderValue,
        onChanged: (v) => onSliderUpdate(v, correct),
      ),
    );
  }
}
