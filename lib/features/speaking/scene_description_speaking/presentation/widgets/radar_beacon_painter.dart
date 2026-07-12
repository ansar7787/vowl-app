import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RadarBeaconPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final bool isCompleted;
  final Color primaryColor;

  RadarBeaconPainter({
    required this.progress,
    required this.isActive,
    required this.isCompleted,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    if (isCompleted) {
      // Completed solid static emerald green glow
      final Paint solidPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.fill;
      final Paint glowPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);

      canvas.drawCircle(center, maxRadius * 0.4, glowPaint);
      canvas.drawCircle(center, maxRadius * 0.35, solidPaint);
      return;
    }

    if (isActive) {
      // Rapid active glowing expansion ripples
      final Paint ripplePaint = Paint()
        ..color = primaryColor.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.w;

      final Paint corePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * progress, ripplePaint);
      canvas.drawCircle(center, maxRadius * 0.4, corePaint);
    } else {
      // Gentle floating sleeping beacons
      final Paint sleepPaint = Paint()
        ..color = primaryColor.withValues(
          alpha: 0.2 + (0.3 * math.sin(progress * math.pi * 2)),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, maxRadius * 0.45, sleepPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarBeaconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isCompleted != isCompleted;
  }
}
