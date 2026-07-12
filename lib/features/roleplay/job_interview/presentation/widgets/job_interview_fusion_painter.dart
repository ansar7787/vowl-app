import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfessionalismFusionPainter extends CustomPainter {
  final double animationValue;
  final double professionalismLevel;
  final Color themeColor;

  ProfessionalismFusionPainter({
    required this.animationValue,
    required this.professionalismLevel,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    Color fusionColor = themeColor;
    if (professionalismLevel > 0.6) {
      fusionColor = Colors.greenAccent;
    } else if (professionalismLevel < 0.3) {
      fusionColor = Colors.redAccent;
    }

    // Draw background dim tracker circle
    final Paint trackPaint = Paint()
      ..color = fusionColor.withValues(alpha: 0.1)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 6, trackPaint);

    // Draw glowing professional level arc
    final Paint arcPaint = Paint()
      ..color = fusionColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * professionalismLevel;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw three revolving telemetry sparks inside the ring
    final Paint sparkPaint = Paint()
      ..color = fusionColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      double sparkAngle =
          (animationValue * 2 * math.pi) + (i * 2 * math.pi / 3);
      double sx = center.dx + (radius - 6) * math.cos(sparkAngle);
      double sy = center.dy + (radius - 6) * math.sin(sparkAngle);
      canvas.drawCircle(Offset(sx, sy), 3.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProfessionalismFusionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.professionalismLevel != professionalismLevel ||
        oldDelegate.themeColor != themeColor;
  }
}
