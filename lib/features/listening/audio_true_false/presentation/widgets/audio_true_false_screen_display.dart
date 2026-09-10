import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioTrueFalseScreenDisplay extends StatelessWidget {
  final String statement;
  final Color color;

  const AudioTrueFalseScreenDisplay({
    super.key,
    required this.statement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 120.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          statement,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
