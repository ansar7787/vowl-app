import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndAnswerAnchorPoint extends StatelessWidget {
  final String question;
  final Color color;
  final bool isDark;

  const ReadAndAnswerAnchorPoint({
    super.key,
    required this.question,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Question: $question',
      // excludeSemantics: the Text child would produce a duplicate
      // announcement — the wrapper label is sufficient.
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.05 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Decorative icon — excluded from semantics; the wrapper covers it.
            ExcludeSemantics(
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz_rounded, color: color, size: 24.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
