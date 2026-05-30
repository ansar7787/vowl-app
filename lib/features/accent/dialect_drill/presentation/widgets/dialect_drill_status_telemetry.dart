import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded, color: color.withValues(alpha: 0.7), size: 18.r)
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3.seconds),
          SizedBox(width: 10.w),
          Text(
            "TELEMETRY PROBE READY FOR REGIONAL ASSIGNMENT",
            style: GoogleFonts.shareTechMono(
              fontSize: 10.sp,
              color: isDark ? Colors.white60 : Colors.black54,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
