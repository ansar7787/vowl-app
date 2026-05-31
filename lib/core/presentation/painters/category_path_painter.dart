import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// A custom painter to draw organic paths connecting quest selection map nodes.
class CategoryPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final GameCategory category;
  final bool isDark;
  final int unlockedLevels;

  CategoryPathPainter({
    required this.points,
    required this.color,
    required this.category,
    required this.isDark,
    required this.unlockedLevels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.r
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start from center top to connect with the card
    path.moveTo(size.width / 2, 0);

    // Draw "Signal Pulse" at the top (Connection Point)
    // 1. Solid Category Core
    canvas.drawCircle(
      Offset(size.width / 2, 0),
      10.r,
      Paint()..color = color,
    );

    // 2. Category Signal Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 30.r),
      );
    canvas.drawCircle(Offset(size.width / 2, 0), 25.r, glowPaint);

    // Continue to first point and beyond
    path.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Organic curved path
      final controlPoint1 = Offset(p1.dx, p1.dy + (p2.dy - p1.dy) / 2);
      final controlPoint2 = Offset(p2.dx, p2.dy - (p2.dy - p1.dy) / 2);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    // Draw the background path (locked)
    canvas.drawPath(path, paint);

    // Draw the active path (up to unlocked levels)
    final activePath = Path();
    activePath.moveTo(size.width / 2, 0);

    if (points.isNotEmpty && unlockedLevels > 0) {
      // Connect to first node
      activePath.lineTo(points[0].dx, points[0].dy);

      // Connect subsequent unlocked nodes
      for (int i = 0; i < unlockedLevels - 1; i++) {
        if (i >= points.length - 1) break;
        final p1 = points[i];
        final p2 = points[i + 1];

        final controlPoint1 = Offset(p1.dx, p1.dy + (p2.dy - p1.dy) / 2);
        final controlPoint2 = Offset(p2.dx, p2.dy - (p2.dy - p1.dy) / 2);

        activePath.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }

      // Glow for active path
      canvas.drawPath(
        activePath,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 16.r
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.r),
      );

      canvas.drawPath(activePath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A custom painter to draw the triangle speech indicator for dynamic mascot dialogue boxes.
class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
