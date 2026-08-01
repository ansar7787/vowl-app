import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContextCluesCaseHeader extends StatelessWidget {
  final int level;
  final int questIndex;
  final Color color;

  const ContextCluesCaseHeader({
    super.key,
    required this.level,
    required this.questIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        children: [
          Text(
            "LINGUISTIC FORENSIC UNIT",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              letterSpacing: 5,
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 1,
                color: color.withValues(alpha: 0.2),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  "CASE #$level-${questIndex + 1}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 40.w,
                height: 1,
                color: color.withValues(alpha: 0.2),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }
}
