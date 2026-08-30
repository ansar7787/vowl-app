import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndAnswerFloatingPassage extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const ReadAndAnswerFloatingPassage({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reading passage: $text',
      // excludeSemantics prevents the Text child from creating a redundant
      // announcement — the wrapper label is the canonical screen reader entry.
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            height: 1.7,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF1E293B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
