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
  final double? width;

  const ContextualUsageOptionChip({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
    this.width,
  });

  String get _displayWord {
    if (text.isEmpty) return text;
    if (text == text.toUpperCase() && text.length > 1) {
      return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    Color tileColor = isDark
        ? color.withValues(alpha: 0.08)
        : Colors.white;
    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.2);
    Color textColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF0F172A);

    if (isSelected) {
      if (isCorrect == true) {
        tileColor = Colors.green.withValues(alpha: isDark ? 0.2 : 0.12);
        borderColor = Colors.green;
        textColor = isDark ? Colors.green.shade200 : Colors.green.shade700;
      } else if (isCorrect == false) {
        tileColor = Colors.red.withValues(alpha: isDark ? 0.2 : 0.12);
        borderColor = Colors.red;
        textColor = isDark ? Colors.red.shade200 : Colors.red.shade700;
      } else {
        tileColor = color.withValues(alpha: isDark ? 0.2 : 0.12);
        borderColor = color;
        textColor = isDark ? Colors.white : color;
      }
    }

    return SizedBox(
      width: width,
      child: ScaleButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: width == null
              ? BoxConstraints(minWidth: 120.w, maxWidth: 165.w)
              : null,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? borderColor.withValues(alpha: 0.25)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.03)),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _displayWord,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
