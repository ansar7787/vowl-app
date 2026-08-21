import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SyllableBlockVisualizer extends StatelessWidget {
  final List<String> syllables;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onPadTap;

  const SyllableBlockVisualizer({
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
    if (syllables.isEmpty) return const SizedBox();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.w,
      runSpacing: 16.h,
      children: List.generate(syllables.length, (index) {
        final isSelected = selectedIndex == index;
        final isCorrect = index == correctIndex;
        
        bool showCorrect = isAnswered && isCorrect;
        bool showWrong = isAnswered && isSelected && !isCorrect;

        Color blockColor = color.withValues(alpha: isDark ? 0.05 : 0.08);
        Color borderColor = isDark ? Colors.white24 : Colors.black12;

        if (showCorrect) {
          blockColor = Colors.green.withValues(alpha: 0.2);
          borderColor = Colors.green;
        } else if (showWrong) {
          blockColor = Colors.red.withValues(alpha: 0.2);
          borderColor = Colors.red;
        } else if (isSelected) {
          blockColor = color.withValues(alpha: 0.3);
          borderColor = color;
        }

        Widget block = GestureDetector(
          onTap: () {
            if (!isAnswered) {
              onPadTap(index, correctIndex);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: borderColor,
                width: isSelected || showCorrect ? 3 : 2,
              ),
              boxShadow: showCorrect
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Text(
              syllables[index],
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: showCorrect ? FontWeight.w900 : FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1,
              ),
            ),
          ),
        );

        if (showCorrect) {
          block = block.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                begin: 1.0,
                end: 1.05,
                duration: 500.ms,
                curve: Curves.easeInOut,
              );
        } else if (showWrong) {
          block = block.animate().shakeX(
                hz: 4,
                amount: 4,
                duration: 400.ms,
              );
        }

        return block;
      }),
    );
  }
}
