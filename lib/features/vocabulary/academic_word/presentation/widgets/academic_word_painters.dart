import 'package:flutter/material.dart';

/// Draws a uniform grid background that fills its canvas.
/// Always wrapped in a [RepaintBoundary] by the parent.
/// [shouldRepaint] compares color so dark/light mode toggles repaint correctly.
class GridPainter extends CustomPainter {
  final Color color;
  const GridPainter(this.color);

  static const double _step = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
