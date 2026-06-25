import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/presentation/widgets/games/dashed_path_utils.dart';

/// A performant CustomPainter to draw curvilinear curvy snake level pathways.
class ModernPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final double dashWidth;
  final double dashSpace;

  ModernPathPainter({
    required this.points,
    required this.color,
    this.thickness = 6.0,
    this.dashWidth = 10.0,
    this.dashSpace = 8.0,
  }) : assert(
         dashWidth > 0,
         'dashWidth must be strictly positive to prevent infinite loops',
       ),
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

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final midY = (p0.dy + p1.dy) / 2;

      path.quadraticBezierTo(p0.dx, midY, p1.dx, p1.dy);
    }

    drawDashedPath(
      canvas,
      path,
      paint,
      dashWidth: dashWidth,
      dashSpace: dashSpace,
    );
  }

  @override
  bool shouldRepaint(covariant ModernPathPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        !listEquals(oldDelegate.points, points);
  }
}
