import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SummarizeStoryProjectorCrank extends StatelessWidget {
  final double crankProgress;
  final Color color;
  final bool isDark;
  final Function(double) onCrank;

  const SummarizeStoryProjectorCrank({
    super.key,
    required this.crankProgress,
    required this.color,
    required this.isDark,
    required this.onCrank,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onCrank(details.delta.dx + details.delta.dy),
      child: Column(
        children: [
          Container(
            width: 80.r,
            height: 80.r,
            decoration: BoxDecoration(
              color: isDark ? Colors.black87 : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20),
              ],
            ),
            child: Transform.rotate(
              angle: crankProgress * 10,
              child: Icon(
                Icons.settings_backup_restore_rounded,
                color: color,
                size: 36.r,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "SPIN TO PROJECT SUMMARY",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 120.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 120.w * crankProgress,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}
