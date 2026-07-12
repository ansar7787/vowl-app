import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Holographic audio wave equalizer spectrum painter
class EqualizerArcPainter extends CustomPainter {
  final double rotationValue; // Selected dial level (0.0 to 1.0)
  final double targetValue; // Empathy target level (0.0 to 1.0)
  final double timeAnimation; // Wave time tick
  final Color themeColor;

  EqualizerArcPainter({
    required this.rotationValue,
    required this.targetValue,
    required this.timeAnimation,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final bool isMatched = (rotationValue - targetValue).abs() < 0.12;

    // Draw background track ring
    final Paint trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 12, trackPaint);

    // Draw Gold Target Zone marker
    final Paint targetPaint = Paint()
      ..color = isMatched ? Colors.greenAccent : Colors.orangeAccent
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Convert target empathy decimal value to radians arc
    final double targetAngleStart =
        -math.pi + (targetValue * 2 * math.pi) - 0.18;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 12),
      targetAngleStart,
      0.36,
      false,
      targetPaint,
    );

    // Draw selected value sweep indicator
    final Paint progressPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = rotationValue * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 20),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Paint jagged audio equalizer spectrum lines around the outer dial ring
    final Paint spectrumPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final int numSpokes = 64;
    for (int i = 0; i < numSpokes; i++) {
      final double angle = (i * 2 * math.pi / numSpokes) - math.pi / 2;

      // Jagged dynamic oscillation height based on current selected level
      double frequencySpeed = 5.0 + (rotationValue * 25.0);
      double phase =
          (timeAnimation * 2 * math.pi) + (i * frequencySpeed * 0.15);
      double waveHeight = math.sin(phase) * (4.r + (rotationValue * 14.r));

      final double startR = radius - 6.r;
      final double endR = radius + 2.r + waveHeight;

      final Offset startPt = Offset(
        center.dx + startR * math.cos(angle),
        center.dy + startR * math.sin(angle),
      );
      final Offset endPt = Offset(
        center.dx + endR * math.cos(angle),
        center.dy + endR * math.sin(angle),
      );

      // Color fades from deep blue (soft) to red (aggressive) based on spoke index
      Color spokeColor =
          Color.lerp(Colors.cyanAccent, Colors.redAccent, rotationValue) ??
          themeColor;
      if (isMatched) spokeColor = Colors.greenAccent;

      spectrumPaint.color = spokeColor.withValues(
        alpha: 0.35 + (0.6 * math.sin(phase).abs()),
      );
      canvas.drawLine(startPt, endPt, spectrumPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EqualizerArcPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.timeAnimation != timeAnimation ||
        oldDelegate.themeColor != themeColor;
  }
}
