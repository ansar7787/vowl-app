import 'package:flutter/material.dart';

/// Background painter rendering an ambient grid pattern for idioms activities.
class GridPainter extends CustomPainter {
  /// Grid line stroke color.
  final Color color;

  /// Creates a [GridPainter] with the specified line [color].
  GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
