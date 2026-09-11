import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioTrueFalseVerdictButtons extends StatelessWidget {
  final bool? selectedVerdict;
  final bool isAnswered;
  final bool? isCorrectState;
  final Function(bool) onVerdictSelected;

  const AudioTrueFalseVerdictButtons({
    super.key,
    required this.selectedVerdict,
    required this.isAnswered,
    required this.isCorrectState,
    required this.onVerdictSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildButton(
            context,
            false,
            "FALSE",
            Icons.close_rounded,
            Colors.redAccent,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildButton(
            context,
            true,
            "TRUE",
            Icons.check_rounded,
            Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    bool value,
    String label,
    IconData icon,
    Color baseColor,
  ) {
    bool isSelected = selectedVerdict == value;
    bool isCorrect = isAnswered && isSelected && isCorrectState == true;
    bool isWrong = isAnswered && isSelected && isCorrectState == false;

    Color buttonColor = isCorrect
        ? Colors.greenAccent
        : (isWrong
              ? Colors.redAccent
              : (isSelected ? baseColor : baseColor.withValues(alpha: 0.1)));

    Color textColor = isSelected ? Colors.white : baseColor;

    return ScaleButton(
      onTap: (isAnswered || selectedVerdict != null)
          ? null
          : () => onVerdictSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 96.h,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: baseColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 32.r),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
