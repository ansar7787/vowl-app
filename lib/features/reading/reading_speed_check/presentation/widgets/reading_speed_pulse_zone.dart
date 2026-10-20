import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

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
        // Passage Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(largeText ? 22.r : 18.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.25 : 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 16.r,
                        color: color.withValues(alpha: 0.85),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'PASSAGE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: color.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  if (wordCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '$wordCount words',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                passage,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: largeText ? 18.sp : 15.5.sp,
                  height: 1.55,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF242838),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // The Stop Button
        ScaleButton(
          onTap: onTapPulse,
          child: Container(
            width: 116.r,
            height: 116.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: isDark ? 0.15 : 0.08),
              border: Border.all(color: color, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stop_circle_rounded,
                        color: color,
                        size: 32.r,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "$_liveWpm",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark ? Colors.white : color,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "WPM",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isDark
                              ? Colors.white70
                              : color.withValues(alpha: 0.75),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(
          onPlay: (c) {
            if (!VowlMotion.shouldReduceMotion(context)) {
              c.repeat(reverse: true);
            }
          },
        )
        .scaleXY(end: 1.05, duration: 800.ms),

        SizedBox(height: 16.h),
        Text(
          "Tap Stop when finished reading",
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF475569),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        if (wpmTarget > 0) ...[
          SizedBox(height: 4.h),
          Text(
            "Target: $wpmTarget WPM",
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              color: color.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
