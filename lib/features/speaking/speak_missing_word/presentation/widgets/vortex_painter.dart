import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering a swirling particle vortex and gravitational beam to dragged tokens.
class VortexPainter extends CustomPainter {
  /// Animation timeline value driving particle rotation.
  final double animationTime;

  /// Center point attracting candidate tokens.
  final Offset? pullCenter;

  /// Position of the actively dragged token.
  final Offset? optionPos;

  /// Primary theme accent color.
  final Color themeColor;

  /// Creates a [VortexPainter].
  VortexPainter({
    required this.animationTime,
    this.pullCenter,
    this.optionPos,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // 1. Draw glowing vortex rings
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w
      ..color = themeColor.withValues(alpha: 0.25);

    final double r1 = math.max(0.0, radius - 20.w);
    final double r2 = math.max(0.0, radius - 40.w);
    if (r1 > 0) canvas.drawCircle(center, r1, ringPaint);
    if (r2 > 0) canvas.drawCircle(center, r2, ringPaint);

    // 2. Draw spinning particles inside vortex
    final Paint particlesPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    const int numPoints = 8;
    for (int i = 0; i < numPoints; i++) {
      final double angle =
          (i * 2 * math.pi / numPoints) + (animationTime * 2 * math.pi);
      final double distance =
          30.w + math.sin(animationTime * 2 * math.pi + i) * 10.w;
      final Offset particlePos =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.drawCircle(particlePos, 3.r, particlesPaint);
    }

    // 3. Draw energy pull beam
    if (pullCenter != null && optionPos != null) {
      final Paint beamPaint = Paint()
        ..color = themeColor
        ..strokeWidth = 3.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.w
        ..style = PaintingStyle.stroke;

      canvas.drawLine(pullCenter!, optionPos!, beamPaint);
      canvas.drawLine(pullCenter!, optionPos!, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VortexPainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
        oldDelegate.pullCenter != pullCenter ||
        oldDelegate.optionPos != optionPos ||
        oldDelegate.themeColor != themeColor;
  }
}
