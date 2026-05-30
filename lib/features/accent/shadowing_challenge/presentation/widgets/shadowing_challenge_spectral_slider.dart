import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ShadowingChallengeSpectralSlider extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final double sliderValue;
  final Function(int, int) onSubmitChoice;
  final Function(double, int) onSliderUpdate;
  final VoidCallback onSliderRelease;

  const ShadowingChallengeSpectralSlider({
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
    required this.onSliderRelease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildConnectedSpeechOrb(options[0], 0, correctIndex, color, isDark)),
            SizedBox(width: 16.w),
            Expanded(child: _buildConnectedSpeechOrb(options[1], 1, correctIndex, color, isDark)),
          ],
        ),
        SizedBox(height: 32.h),
        _buildSliderBar(correctIndex, color),
        SizedBox(height: 12.h),
        Text(
          "SLIDE LOCK SEEKER NEEDLE CONSOLE",
          style: GoogleFonts.shareTechMono(
            color: color.withValues(alpha: 0.7),
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedSpeechOrb(String text, int index, int correctIndex, Color color, bool isDark) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    
    Color orbColor = color.withValues(alpha: 0.1);
    Color textColor = color;
    if (isAnswered && isSelected) {
      orbColor = correct ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2);
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
    }

    return ScaleButton(
      onTap: () => onSubmitChoice(index, correctIndex),
      child: Container(
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: orbColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isAnswered && isSelected 
              ? textColor 
              : color.withValues(alpha: isSelected ? 1.0 : 0.3), 
            width: 3
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? (correct ? Colors.greenAccent.withValues(alpha: 0.3) : color.withValues(alpha: 0.3)) 
                : Colors.transparent, 
              blurRadius: 15
            )
          ],
        ),
        child: Center(
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp, 
              fontWeight: FontWeight.bold, 
              color: textColor,
              height: 1.2
            )
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: (2 + index).seconds),
    );
  }

  Widget _buildSliderBar(int correct, Color color) {
    return GestureDetector(
      onPanEnd: (_) => onSliderRelease(),
      child: SliderTheme(
        data: SliderThemeData(
          activeTrackColor: color,
          inactiveTrackColor: color.withValues(alpha: 0.15),
          thumbColor: color,
          overlayColor: color.withValues(alpha: 0.2),
          trackHeight: 12.h,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 18.r),
        ),
        child: Slider(
          value: sliderValue,
          onChanged: (v) => onSliderUpdate(v, correct),
        ),
      ),
    );
  }
}
