import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SoundwaveSpectrumPainter extends CustomPainter {
  final double animationValue;
  final bool isListening;
  final Color themeColor;

  SoundwaveSpectrumPainter({
    required this.animationValue,
    required this.isListening,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final Paint paint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double midY = height / 2;

    final Path path = Path();
    path.moveTo(0, midY);

    final int points = 50;
    for (int i = 0; i <= points; i++) {
      final double x = (width / points) * i;
      // Combine multiple harmonic frequencies for a high-tech biosensor audio wave look
      final double wave1 = math.sin(
        (i * 0.25) - (animationValue * 2 * math.pi * 3),
      );
      final double wave2 = math.cos(
        (i * 0.12) + (animationValue * 2 * math.pi * 1.5),
      );
      final double envelope = math.sin(
        (i / points) * math.pi,
      ); // Fade edges to 0

      final double y = midY + (wave1 * 12.h + wave2 * 6.h) * envelope;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SoundwaveSpectrumPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isListening != isListening ||
        oldDelegate.themeColor != themeColor;
  }
}
