import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShortAnswerInkwell extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnswered;
  final int wordCount;
  final double inkLevel;
  final Color color;
  final bool isDark;

  const ShortAnswerInkwell({
    super.key,
    required this.controller,
    required this.isAnswered,
    required this.wordCount,
    required this.inkLevel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 5,
            enabled: !isAnswered,
            style: TextStyle(
              fontFamily: 'Spectral',
              fontSize: 16.sp,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: "Let the ink flow...",
              hintStyle: TextStyle(
                fontFamily: 'Spectral',
                color: isDark ? Colors.white30 : Colors.black38,
              ),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ink volume:",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "$wordCount words",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 10.sp,
                  color: wordCount >= 10
                      ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
                      : (isDark ? Colors.redAccent : const Color(0xFFDC2626)),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              AnimatedContainer(
                duration: 300.milliseconds,
                width: MediaQuery.of(context).size.width * inkLevel * 0.7,
                height: 6.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.5)],
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(target: inkLevel).shimmer(duration: 2.seconds);
  }
}
