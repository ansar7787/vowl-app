import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
class PrefixSuffixMissionControl extends StatelessWidget {
  final Color primaryColor;

  const PrefixSuffixMissionControl({
    super.key,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            "DOCK THE ROVER",
            style: TextStyle(fontFamily: 'RobotoMono', 
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2.seconds),
        SizedBox(height: 8.h),
        Text(
          "LEXICAL MISSION IN PROGRESS",
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 8.sp,
            color: primaryColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
