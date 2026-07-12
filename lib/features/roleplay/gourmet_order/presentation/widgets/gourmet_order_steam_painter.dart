import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SteamWavesPainter extends CustomPainter {
  final double animationValue;
  final Color themeColor;

  SteamWavesPainter({required this.animationValue, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = themeColor.withValues(alpha: 0.15 * (1.0 - animationValue))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;

    // Draw three elegant wavy steam columns rising upward
    for (int col = 0; col < 3; col++) {
      final double startX = (width * 0.25) + (col * width * 0.25);
      final Path path = Path();

      path.moveTo(startX, height);

      for (double y = height; y > 0; y -= 10) {
        // Calculate undulating horizontal offsets
        double progress = (height - y) / height;
        double wavePhase =
            (progress * 2 * math.pi) - (animationValue * 2 * math.pi);
        double xOffset = math.sin(wavePhase) * 6.r * (1.0 - progress);

        path.lineTo(startX + xOffset, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SteamWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.themeColor != themeColor;
  }
}
