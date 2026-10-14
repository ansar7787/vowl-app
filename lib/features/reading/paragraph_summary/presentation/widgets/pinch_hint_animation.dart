import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class PinchHintAnimation extends StatelessWidget {
  final Color color;

  const PinchHintAnimation({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return IgnorePointer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 24.r,
                ),
              )
              .animate(
                onPlay: (controller) {
                  if (!reduceMotion) controller.repeat();
                },
              )
              .fadeIn(duration: 400.ms)
              .moveX(
                begin: -80.w,
                end: -10.w,
                duration: 1200.ms,
                curve: Curves.easeInOutCubic,
              )
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 1200.ms,
                curve: Curves.easeInOutCubic,
              )
              .fadeOut(delay: 800.ms, duration: 400.ms),
          SizedBox(width: 40.w),
          Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.8),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.arrow_back_rounded, color: color, size: 24.r),
              )
              .animate(
                onPlay: (controller) {
                  if (!reduceMotion) controller.repeat();
                },
              )
              .fadeIn(duration: 400.ms)
              .moveX(
                begin: 80.w,
                end: 10.w,
                duration: 1200.ms,
                curve: Curves.easeInOutCubic,
              )
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(0.8, 0.8),
                duration: 1200.ms,
                curve: Curves.easeInOutCubic,
              )
              .fadeOut(delay: 800.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
