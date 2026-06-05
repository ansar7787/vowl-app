import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
class AcademicWordInstruction extends StatelessWidget {
  final Color color;

  const AcademicWordInstruction({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "THRUST WORD INTO THE THESIS",
        style: TextStyle(fontFamily: 'RobotoMono', 
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 2,
        ),
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .shimmer(duration: 2.seconds, color: color.withValues(alpha: 0.3));
  }
}
