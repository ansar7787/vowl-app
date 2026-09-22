import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrueFalseReadingPassage extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;

  const TrueFalseReadingPassage({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        passage,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          height: 1.6,
          fontWeight: FontWeight.w500,
          color: isDark
              ? Colors.white.withValues(alpha: 0.9)
              : const Color(0xFF2D3142),
        ),
      ),
    );
  }
}
