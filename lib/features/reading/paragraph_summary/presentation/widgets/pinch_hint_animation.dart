import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated badge displaying pinch gesture guidance to reveal distilled keywords.
class PinchHintAnimation extends StatelessWidget {
  /// Theme accent color applied to icon and text.
  final Color color;

  /// Creates a [PinchHintAnimation] widget.
  const PinchHintAnimation({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : Colors.white)
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pinch_rounded,
              color: color,
              size: 18.r,
            ),
            SizedBox(width: 8.w),
            Text(
              'Pinch or tap to reveal',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      )
          .animate(
            onPlay: (controller) {
              if (!reduceMotion) controller.repeat(reverse: true);
            },
          )
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.03, 1.03),
            duration: 900.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
