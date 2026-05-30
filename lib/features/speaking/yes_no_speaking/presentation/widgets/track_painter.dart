import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrackPainter extends CustomPainter {
  final double tiltValue; // -1.0 to 1.0
  final Color themeColor;

  TrackPainter({required this.tiltValue, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    final Paint trackPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 4.h
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint activePaint = Paint()
      ..color = tiltValue < 0 ? Colors.redAccent : Colors.greenAccent
      ..strokeWidth = 5.h
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final Path path = Path();
    path.moveTo(0, midY);

    // Apply tension deflection curve (sine)
    final double centerX = width / 2;
    final double sphereX = centerX + (tiltValue * (width / 2 - 40.w));
    
    for (double x = 0; x <= width; x += 4.w) {
      final double distanceToSphere = (x - sphereX).abs();
      final double deflection = math.max(0.0, 1.0 - (distanceToSphere / 60.w));
      
      // Bend downwards up to 12.h
      final double y = midY + (math.sin(deflection * math.pi / 2) * 12.h * tiltValue.abs());
      path.lineTo(x, y);
    }

    canvas.drawPath(path, trackPaint);

    if (tiltValue != 0) {
      final Path activePath = Path();
      activePath.moveTo(centerX, midY);
      
      final double start = math.min(centerX, sphereX);
      final double end = math.max(centerX, sphereX);
      
      for (double x = start; x <= end; x += 4.w) {
        final double distanceToSphere = (x - sphereX).abs();
        final double deflection = math.max(0.0, 1.0 - (distanceToSphere / 60.w));
        final double y = midY + (math.sin(deflection * math.pi / 2) * 12.h * tiltValue.abs());
        activePath.lineTo(x, y);
      }
      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrackPainter oldDelegate) {
    return oldDelegate.tiltValue != tiltValue || oldDelegate.themeColor != themeColor;
  }
}
