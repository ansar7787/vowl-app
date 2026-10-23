import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centered floating anchor bubble displaying the base word in collocation challenges.
class CollocationAnchorBubble extends StatelessWidget {
  /// Anchor word string rendered prominently in the bubble.
  final String text;

  /// Background color styling the anchor bubble.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Creates a [CollocationAnchorBubble] widget.
  const CollocationAnchorBubble({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        )
        .animate(onPlay: reduceMotion ? null : (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut);
  }
}
