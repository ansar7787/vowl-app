import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ConflictResolverConflictCard extends StatelessWidget {
  final String scene;
  final Color color;
  final bool isDark;
  final double rotation;

  const ConflictResolverConflictCard({
    super.key,
    required this.scene,
    required this.color,
    required this.isDark,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    Color emotionalColor =
        Color.lerp(Colors.cyanAccent, Colors.redAccent, rotation) ?? color;
    if ((rotation - 0.75).abs() < 0.12) {
      emotionalColor = Colors.greenAccent;
    }

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: emotionalColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: emotionalColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: emotionalColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.forum_rounded,
                  color: emotionalColor,
                  size: 24.r,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONFLICT SCENARIO DETECTED:",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    color: emotionalColor,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  scene,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17.sp,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
