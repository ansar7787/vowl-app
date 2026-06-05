import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ContextualUsageOptionChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const ContextualUsageOptionChip({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color tileColor = isDark ? color.withValues(alpha: 0.1) : Colors.white;
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (isSelected) {
      if (isCorrect == true) {
        tileColor = Colors.green.withValues(alpha: 0.2);
        borderColor = Colors.green;
        textColor = isDark ? Colors.white : Colors.green.shade700;
      } else if (isCorrect == false) {
        tileColor = Colors.red.withValues(alpha: 0.2);
        borderColor = Colors.red;
        textColor = isDark ? Colors.white : Colors.red.shade700;
      } else {
        tileColor = color.withValues(alpha: 0.3);
        borderColor = color;
        textColor = isDark ? Colors.white : color;
      }
    }

    return ScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(minWidth: 140.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 15,
              ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
