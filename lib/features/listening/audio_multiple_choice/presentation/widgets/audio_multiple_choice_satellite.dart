import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      if (isSelected) return isDark ? Colors.black87 : Colors.white;
      return isDark ? color.withValues(alpha: 0.2) : Colors.white;
    }

    Color getBorderColor() {
      if (isCorrect) return Colors.greenAccent;
      if (isWrong) return Colors.redAccent;
      if (isSelected) return color;
      return color.withValues(alpha: 0.5);
    }

    Color getTextColor() {
      if (isCorrect) return Colors.black87;
      if (isWrong) return Colors.white;
      if (isSelected) return color;
      return isDark ? Colors.white : color;
    }

    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 100.r,
        height: 100.r,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: getBgColor(),
          shape: BoxShape.circle,
          border: Border.all(color: getBorderColor(), width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15)]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: getTextColor(),
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
