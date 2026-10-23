import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Cosmic grid canvas painter for the cosmic warp background.
class CosmicGridPainter extends CustomPainter {
  /// Grid line stroke color.
  final Color color;

  /// Creates a [CosmicGridPainter] with the specified [color].
  CosmicGridPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Particle trail painter illustrating trajectory lines behind dragged shards.
class TrailPainter extends CustomPainter {
  /// Ordered point history of the drag gesture.
  final List<Offset> points;

  /// Theme accent color.
  final Color color;

  /// Creates a [TrailPainter] tracking [points] with [color].
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

  @override
  bool shouldRepaint(covariant TrailPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

/// Rotating circular vortex painter depicting the warp portal core.
class VortexPainter extends CustomPainter {
  /// Portal line stroke color.
  final Color color;

  /// Creates a [VortexPainter] with the specified line [color].
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
        center +
            Offset(
              math.cos(angle + 0.5) * (radius + 10),
              math.sin(angle + 0.5) * (radius + 10),
            ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Geometric circuit and constellation pattern painter for sci-fi card borders.
class TechPatternPainter extends CustomPainter {
  /// Line stroke color.
  final Color color;

  /// Creates a [TechPatternPainter] with the specified line [color].
  TechPatternPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width, size.height * 0.8),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 3, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
