import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopicMachineHead extends StatelessWidget {
  final Color primaryColor;
  final String? emoji;

  const TopicMachineHead({
    super.key,
    required this.primaryColor,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 120.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Outer Energy Rings
          Container(
            width: 160.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 20)
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.2),
              ),

          // The Core Machine
          Container(
            width: 130.w,
            height: 70.h,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40.r)),
              border: Border.all(color: primaryColor, width: 3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.2),
                  Colors.black,
                ],
              ),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: -5)
              ],
            ),
            child: Center(
              child: emoji != null
                  ? Text(
                      emoji!,
                      style: TextStyle(fontSize: 32.sp),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds)
                  : Icon(Icons.bolt_rounded, color: primaryColor, size: 30.r),
            ),
          ),
          
          // Vent Details
          Positioned(
            top: 5.h,
            child: Row(
              children: List.generate(3, (i) => Container(
                width: 15.w, height: 2.h,
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                color: primaryColor.withValues(alpha: 0.5),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
