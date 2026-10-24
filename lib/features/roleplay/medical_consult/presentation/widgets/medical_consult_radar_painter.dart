import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering medical laser scan radar grids and sweep lines.
class BiometricRadarPainter extends CustomPainter {
  /// Animation progress value (0.0 to 1.0).
  final double animationValue;

  /// Theme accent color.
  final Color themeColor;

  /// Creates a [BiometricRadarPainter] instance.
  BiometricRadarPainter({
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;

    // Draw horizontal scan grids
    for (double y = 0; y < height; y += 24.h) {
      canvas.drawLine(Offset(0, y), Offset(width, y), linePaint);
    }
    // Draw vertical grids
    for (double x = 0; x < width; x += 24.w) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), linePaint);
    }

    // Draw sweeping green medical laser line moving from top to bottom
    final Paint laserPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25)
      ..strokeWidth = 2.0;

    final double laserY = height * animationValue;
    canvas.drawLine(Offset(0, laserY), Offset(width, laserY), laserPaint);

    final Paint laserGlowPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, laserY - 8.h, width, 16.h),
      laserGlowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BiometricRadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.themeColor != themeColor;
  }
}
