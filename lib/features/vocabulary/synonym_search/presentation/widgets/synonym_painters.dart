import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CosmicGridPainter extends CustomPainter {
  final Color color;
  CosmicGridPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0;
    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrailPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  TrailPainter(this.points, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final double progress = i / points.length;
      dotPaint.color = color.withValues(alpha: progress * 0.4);
      canvas.drawCircle(points[i], (2 + progress * 3).r, dotPaint);
    }
  }
  @override bool shouldRepaint(TrailPainter oldDelegate) => true;
}

class VortexPainter extends CustomPainter {
  final Color color;
  VortexPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 5; i++) {
      double radius = (i + 1) * 15.0;
      canvas.drawCircle(center, radius, paint);
      double angle = i * math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        center + Offset(math.cos(angle + 0.5) * (radius + 10), math.sin(angle + 0.5) * (radius + 10)),
        paint,
      );
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TechPatternPainter extends CustomPainter {
  final Color color;
  TechPatternPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width * 0.3, size.height * 0.2), paint);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.2), Offset(size.width * 0.5, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.7, size.height * 0.8), Offset(size.width, size.height * 0.8), paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 3, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
