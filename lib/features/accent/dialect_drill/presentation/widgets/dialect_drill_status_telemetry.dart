import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DialectDrillStatusTelemetry extends StatelessWidget {
  final Color color;
  final bool isDark;

  const DialectDrillStatusTelemetry({
    super.key,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                Icons.touch_app_rounded,
                color: color.withValues(alpha: 0.8),
                size: 26.r,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(begin: -0.2, end: 0.2),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              "Drag the pin to match the dialect",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
