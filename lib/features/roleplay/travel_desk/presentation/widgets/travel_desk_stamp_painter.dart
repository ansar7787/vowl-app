import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StampRipplePainter extends CustomPainter {
  final Offset impactOffset;
  final double animationValue;
  final Color themeColor;

  StampRipplePainter({
    required this.impactOffset,
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue == 0 || animationValue == 1) return;

    final Paint ringPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8 * (1.0 - animationValue))
      ..strokeWidth = 3.0 * (1.0 - animationValue)
      ..style = PaintingStyle.stroke;

    final Paint auraPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25 * (1.0 - animationValue))
      ..style = PaintingStyle.fill;

    double radius = 40.r * animationValue;
    
    // Draw expanding shockwave ring
    canvas.drawCircle(impactOffset, radius, ringPaint);
    canvas.drawCircle(impactOffset, radius * 0.7, auraPaint);

    // Draw little flying ink particles
    final Paint sparkPaint = Paint()
      ..color = themeColor.withValues(alpha: 1.0 - animationValue)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      double angle = i * math.pi / 4;
      double dist = radius * 1.2;
      double px = impactOffset.dx + dist * math.cos(angle);
      double py = impactOffset.dy + dist * math.sin(angle);
      canvas.drawCircle(Offset(px, py), 2.5.r * (1.0 - animationValue), sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StampRipplePainter oldDelegate) {
    return oldDelegate.impactOffset != impactOffset ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.themeColor != themeColor;
  }
}
