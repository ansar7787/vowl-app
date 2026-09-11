import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioMultipleChoiceSatellite extends StatelessWidget {
  final int index;
  final String text;
  final int correct;
  final Color color;
  final int? selectedIndex;
  final bool isAnswered;
  final bool? isCorrectState;
  final VoidCallback onTap;

  const AudioMultipleChoiceSatellite({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrectState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedIndex == index;
    final isCorrect = isAnswered && index == correct && isCorrectState == true;
    final isWrong = isAnswered && isSelected && isCorrectState == false;

    Color getBgColor() {
      if (isCorrect) return Colors.greenAccent;
      if (isWrong) return Colors.redAccent;
      if (isSelected) return color;
      return isDark ? Colors.grey[900]! : Colors.white;
    }

    Color getBorderColor() {
      if (isCorrect) return Colors.greenAccent;
      if (isWrong) return Colors.redAccent;
      if (isSelected) return color;
      return isDark
          ? color.withValues(alpha: 0.3)
          : color.withValues(alpha: 0.2);
    }

    Color getTextColor() {
      if (isCorrect) return Colors.black87;
      if (isWrong) return Colors.white;
      if (isSelected) return Colors.white;
      return isDark ? Colors.white : color;
    }

    return ScaleButton(
          onTap: onTap,
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minWidth: isSelected ? 90.r : 80.r,
              maxWidth: 130.r,
              maxHeight: isSelected ? 90.h : 80.h,
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
            decoration: BoxDecoration(
              color: getBgColor(),
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(
                color: getBorderColor(),
                width: isSelected ? 4 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: getBgColor().withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isSelected ? 14.sp : 12.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: getTextColor(),
                  height: 1.1,
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (100 * index).ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}
