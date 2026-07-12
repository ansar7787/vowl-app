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
    final isSelected = selectedIndex == index;
    final isCorrect = isAnswered && index == correct && isCorrectState == true;
    final isWrong = isAnswered && isSelected && isCorrectState == false;
    final tileColor = isCorrect
        ? Colors.greenAccent
        : (isWrong ? Colors.redAccent : (isSelected ? Colors.white : color));

    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 80.r,
        height: 80.r,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: tileColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tileColor.withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
