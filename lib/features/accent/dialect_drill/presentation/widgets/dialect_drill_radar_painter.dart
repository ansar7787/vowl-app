import 'dart:math' as math;
import 'package:flutter/material.dart';

// Hologram Radar Custom Painter
class HologramRadarPainter extends CustomPainter {
  final double sweepAngle;
  final Color themeColor;
  final bool isDark;

  HologramRadarPainter({
    required this.sweepAngle,
    required this.themeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    // Grid lines paint
    final gridPaint = Paint()
      ..color = themeColor.withValues(alpha: isDark ? 0.08 : 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Concentric grid circles
    for (double i = 0.2; i <= 1.0; i += 0.2) {
      canvas.drawCircle(center, maxRadius * i, gridPaint);
    }

    // Grid crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Diagonal auxiliary lines
    canvas.drawLine(
      Offset(center.dx - maxRadius * 0.707, center.dy - maxRadius * 0.707),
      Offset(center.dx + maxRadius * 0.707, center.dy + maxRadius * 0.707),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius * 0.707, center.dy + maxRadius * 0.707),
      Offset(center.dx + maxRadius * 0.707, center.dy - maxRadius * 0.707),
      gridPaint,
    );

    // Sweep cone paint (glowing scanning effect)
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          themeColor.withValues(alpha: 0.15),
          themeColor.withValues(alpha: 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle - 0.4,
        0.4,
        false,
      )
      ..close();

    canvas.drawPath(path, sweepPaint);

    // Dynamic scanning edge ray
    final edgePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    
    final edgeX = center.dx + maxRadius * math.cos(sweepAngle);
    final edgeY = center.dy + math.sin(sweepAngle) * maxRadius;
    canvas.drawLine(center, Offset(edgeX, edgeY), edgePaint);
  }

  @override
  bool shouldRepaint(covariant HologramRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isDark != isDark;
  }
}
