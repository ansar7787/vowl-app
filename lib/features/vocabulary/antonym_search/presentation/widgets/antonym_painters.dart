import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FluxGridPainter extends CustomPainter {
  final bool isDark;
  FluxGridPainter(this.isDark);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 40.w) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40.w) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CorePainter extends CustomPainter {
  final Color color;
  CorePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 10; i++) {
      canvas.drawCircle(center, (i + 1) * 7.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PlasmaArcPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  PlasmaArcPainter(this.start, this.end, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(start.dx, start.dy);
    final random = math.Random();
    final dist = (end - start).distance;
    final segments = (dist / 20).clamp(5, 15).toInt();
    for (int i = 1; i <= segments; i++) {
      final double t = i / segments;
      final p = Offset.lerp(start, end, t)!;
      if (i < segments) {
        path.lineTo(
          p.dx + (random.nextDouble() * 30 - 15),
          p.dy + (random.nextDouble() * 30 - 15),
        );
      } else {
        path.lineTo(end.dx, end.dy);
      }
    }
    canvas.drawPath(path, paint);
    paint.strokeWidth = 12;
    paint.color = color.withValues(alpha: 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
