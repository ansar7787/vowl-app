import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompassTicksPainter extends CustomPainter {
  final Color color;
  CompassTicksPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.r
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 36; i++) {
      final angle = (i * 10) * (math.pi / 180);
      final isMajor = i % 9 == 0;
      final start = Offset(
        center.dx + (radius - (isMajor ? 15.r : 8.r)) * math.cos(angle),
        center.dy + (radius - (isMajor ? 15.r : 8.r)) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CompassTicksPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
