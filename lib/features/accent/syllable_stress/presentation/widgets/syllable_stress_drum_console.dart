import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SyllableStressDrumConsole extends StatelessWidget {
  final List<String> syllables;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onPadTap;

  const SyllableStressDrumConsole({
    super.key,
    required this.syllables,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onPadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.w,
      runSpacing: 16.h,
      alignment: WrapAlignment.center,
      children: List.generate(
        syllables.length, 
        (i) => _buildDrumPad(i, syllables[i], correctIndex, color, isDark)
      ),
    );
  }

  Widget _buildDrumPad(int index, String text, int correct, Color color, bool isDark) {
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = isAnswered && index == correct;
    final bool isWrong = isAnswered && isSelected && index != correct;
    
    Color padColor = isCorrect ? Colors.greenAccent : (isWrong ? Colors.redAccent : color);
    Color contentColor = isSelected ? padColor : color;
    if (isAnswered && index == correct) {
      padColor = Colors.greenAccent;
      contentColor = Colors.greenAccent;
    }

    return ScaleButton(
      onTap: () => onPadTap(index, correct),
      child: AnimatedContainer(
        duration: 150.milliseconds,
        width: 90.r, height: 90.r,
        decoration: BoxDecoration(
          color: isSelected 
            ? padColor.withValues(alpha: 0.2) 
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected || (isAnswered && index == correct)
              ? padColor 
              : color.withValues(alpha: 0.3), 
            width: 3
          ),
          boxShadow: isSelected ? [BoxShadow(color: padColor.withValues(alpha: 0.3), blurRadius: 15)] : [],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text.toUpperCase(), 
                style: TextStyle(fontFamily: 'RobotoMono', 
                  fontSize: 18.sp, 
                  fontWeight: FontWeight.bold, 
                  color: isSelected || (isAnswered && index == correct) 
                    ? contentColor 
                    : (isDark ? Colors.white : Colors.black87)
                )
              ),
              if (index == correct && isAnswered) ...[
                SizedBox(height: 4.h),
                Icon(Icons.bolt_rounded, color: Colors.greenAccent, size: 18.r).animate().scale(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
