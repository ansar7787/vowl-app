import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ReadingSpeedPulseZone extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;
  final int timerValue;
  final int timeLimit;
  final int wordCount;
  final int wpmTarget;
  final VoidCallback onTapPulse;
  final bool largeText;

  const ReadingSpeedPulseZone({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    required this.timerValue,
    required this.timeLimit,
    required this.wordCount,
    required this.wpmTarget,
    required this.onTapPulse,
    this.largeText = false,
  });

  int get _liveWpm {
    final elapsed = timeLimit - timerValue;
    if (elapsed <= 0) return 0;
    return (wordCount / (elapsed / 60)).round();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(largeText ? 32.r : 28.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            passage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: largeText ? 24.sp : 18.sp,
              height: 1.5,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 32.h),

        // The Stop Button
        ScaleButton(
              onTap: onTapPulse,
              child: Container(
                width: 140.r,
                height: 140.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                  border: Border.all(color: color, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle_rounded, color: color, size: 36.r),
                    SizedBox(height: 4.h),
                    Text(
                      "$_liveWpm",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark ? Colors.white : color,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "WPM",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: isDark
                            ? Colors.white70
                            : color.withValues(alpha: 0.7),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(end: 1.05, duration: 800.ms),

        SizedBox(height: 24.h),
        Text(
          "TAP TO STOP TIMER & ANSWER",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            color: color.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8.h),
        if (wpmTarget > 0)
          Text(
            "TARGET: $wpmTarget WPM",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              color: color.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
      ],
    );
  }
}
