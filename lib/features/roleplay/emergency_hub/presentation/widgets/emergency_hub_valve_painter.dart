import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering the emergency pressure valve wheel and hazard track.
class EmergencyValvePainter extends CustomPainter {
  /// Normalized rotation value of the valve wheel.
  final double rotationValue;

  /// Whether the valve wheel is sufficiently aligned to the unlock threshold.
  final bool isValveAligned;

  /// Progress tick driving warning animations.
  final double animationTime;

  /// Theme error accent color.
  final Color errorColor;

  /// Theme success accent color.
  final Color correctColor;

  /// Creates an [EmergencyValvePainter] instance.
  EmergencyValvePainter({
    required this.rotationValue,
    required this.isValveAligned,
    required this.animationTime,
    required this.errorColor,
    required this.correctColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Hazard yellow/black warning outer stripes track
    final Paint hazardPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.w;

    final int numStripes = 24;
    for (int i = 0; i < numStripes; i++) {
      final double angleStart = (i * 2 * math.pi / numStripes);
      final double sweep = math.pi / numStripes;

      hazardPaint.color = (i % 2 == 0) ? Colors.amberAccent : Colors.black87;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 8.w),
        angleStart + (animationTime * 0.5),
        sweep,
        false,
        hazardPaint,
      );
    }

    // Outer thick pressure steel track
    final Paint steelTrackPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 4.w
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 16.w, steelTrackPaint);

    // Indicator sectors (AWAITING / ALIGNED)
    final Paint sectorPaint = Paint()
      ..color = isValveAligned
          ? correctColor.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 20.w, sectorPaint);
  }

  @override
  bool shouldRepaint(covariant EmergencyValvePainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.isValveAligned != isValveAligned ||
        oldDelegate.animationTime != animationTime ||
        oldDelegate.errorColor != errorColor ||
        oldDelegate.correctColor != correctColor;
  }
}
