import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AntonymPulsar extends StatelessWidget {
  final bool isTop;
  final bool targetIsPositive;
  final VoidCallback? onTap;

  const AntonymPulsar({
    super.key,
    required this.isTop,
    required this.targetIsPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTop ? const Color(0xFF00E5FF) : const Color(0xFFFF4D00);
    final isActive = isTop != targetIsPositive;

    return Positioned(
          top: isTop ? 10.h : null,
          bottom: isTop ? null : 10.h,
          left: 20.w,
          right: 20.w,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 80.h,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: color.withValues(alpha: isActive ? 1.0 : 0.2),
                width: isActive ? 3 : 1,
              ),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 25,
                  ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isTop ? "POSITIVE PULSAR [+]" : "NEGATIVE PULSAR [-]",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: color.withValues(alpha: isActive ? 1.0 : 0.3),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 4.seconds);
  }
}
