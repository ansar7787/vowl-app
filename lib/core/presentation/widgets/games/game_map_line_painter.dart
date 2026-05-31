import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A performant CustomPainter to draw straight or dashed quest connection tracks.
class GameMapLinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final bool isDashed;
  final double dashWidth;
  final double dashSpace;

  GameMapLinePainter({
    required this.points,
    required this.color,
    this.thickness = 4.0,
    this.isDashed = false,
    this.dashWidth = 10.0,
    this.dashSpace = 8.0,
  }) : assert(dashWidth > 0, 'dashWidth must be strictly positive to prevent infinite loops'),
       assert(dashSpace >= 0, 'dashSpace must be non-negative');

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (isDashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant GameMapLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.isDashed != isDashed ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        !listEquals(oldDelegate.points, points);
  }
}
