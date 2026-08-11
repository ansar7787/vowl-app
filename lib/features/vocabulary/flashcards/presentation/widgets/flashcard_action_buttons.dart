import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FlashcardActionButtons extends StatelessWidget {
  final bool isFlipped;
  final bool isTransitioning;
  final bool isDark;
  final VoidCallback onAgain;
  final VoidCallback onGotIt;

  const FlashcardActionButtons({
    super.key,
    required this.isFlipped,
    required this.isTransitioning,
    required this.isDark,
    required this.onAgain,
    required this.onGotIt,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFlipped) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                  Icons.touch_app_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                  size: 30.r,
                )
                .animate(onPlay: (c) => c.repeat())
                .moveY(
                  begin: 4,
                  end: -4,
                  duration: 1.seconds,
                  curve: Curves.easeInOut,
                ),
            SizedBox(height: 8.h),
            Text(
              'TAP CARD TO REVEAL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_double_arrow_left_rounded,
            color: Colors.red.withValues(alpha: 0.5),
            size: 24.r,
          ).animate(onPlay: (c) => c.repeat()).moveX(begin: 2, end: -2, duration: 1.seconds),
          SizedBox(width: 12.w),
          Text(
            'SWIPE TO DECIDE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: isDark ? Colors.white54 : Colors.black45,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: Colors.green.withValues(alpha: 0.5),
            size: 24.r,
          ).animate(onPlay: (c) => c.repeat()).moveX(begin: -2, end: 2, duration: 1.seconds),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
    );
  }
}
