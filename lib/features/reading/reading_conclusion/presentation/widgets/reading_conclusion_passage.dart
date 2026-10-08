import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadingConclusionPassage extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;

  const ReadingConclusionPassage({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_rounded, color: color, size: 28.r),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: Text(
              passage,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
