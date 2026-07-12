import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrueFalseReadingStatement extends StatelessWidget {
  final String statement;
  final Color color;
  final bool isDark;

  const TrueFalseReadingStatement({
    super.key,
    required this.statement,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '"$statement"',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: isDark ? color : color.withValues(alpha: 0.95),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
