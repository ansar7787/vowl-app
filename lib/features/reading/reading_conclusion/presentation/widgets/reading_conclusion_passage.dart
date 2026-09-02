import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_motion_rounded, color: color, size: 32.r),
              SizedBox(height: 16.h),
              Text(
                passage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 4, duration: 2.seconds);
  }
}
