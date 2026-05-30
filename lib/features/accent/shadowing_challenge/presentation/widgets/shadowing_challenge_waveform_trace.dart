import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ShadowingChallengeWaveformTrace extends StatelessWidget {
  final Color color;
  final bool isDark;
  final bool isPreviewing;
  final double traceProgress;

  const ShadowingChallengeWaveformTrace({
    super.key,
    required this.color,
    required this.isDark,
    required this.isPreviewing,
    required this.traceProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12)
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WaveformPainter(color.withValues(alpha: 0.15)),
            ),
          ),
          if (isPreviewing)
            Positioned.fill(
              child: CustomPaint(
                painter: _WaveformPainter(color, progress: traceProgress),
              ),
            ),
          Positioned(
            left: 10.w,
            top: 10.h,
            child: Row(
              children: [
                Container(
                  width: 8.r, height: 8.r,
                  decoration: BoxDecoration(
                    color: isPreviewing ? Colors.greenAccent : color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  isPreviewing ? "PLAYING PHONETIC WAVE" : "WAVE READY",
                  style: GoogleFonts.shareTechMono(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final double progress;
  _WaveformPainter(this.color, {this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    double mid = size.height / 2;
    path.moveTo(0, mid);

    for (double i = 0; i <= size.width * progress; i += 5) {
      double y = mid + (math.sin(i / 10.0) * 20.0) + (math.cos(i / 15.0) * 10.0);
      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
