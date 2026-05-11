import 'package:flutter/material.dart';

class ModernPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double thickness;

  ModernPathPainter({
    required this.points,
    required this.color,
    this.thickness = 6.0,
  });

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

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Calculate control point for a smooth curve
      // We want a vertical "S" shape or smooth snake
      final midY = (p0.dy + p1.dy) / 2;

      path.quadraticBezierTo(
        p0.dx, // Control DX
        midY, // Control DY
        p1.dx, // Target DX
        p1.dy, // Target DY
      );
    }

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 8.0;
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
  bool shouldRepaint(covariant ModernPathPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.thickness != thickness || 
           oldDelegate.points.length != points.length;
  }
}
