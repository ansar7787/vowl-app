import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CompleteSentenceTrajectoryPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  const CompleteSentenceTrajectoryPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Calculate a control point for a subtle upward curve between start and end.
    final controlPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 - 40.h,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        controlPoint.dx,
        controlPoint.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      end,
      8.r,
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  // FIX: was `return true` unconditionally — caused unnecessary redraws on
  // every frame even when the painter's inputs hadn't changed.
  // Now only repaints when start, end, or color actually differ.
  @override
  bool shouldRepaint(CompleteSentenceTrajectoryPainter old) =>
      old.start != start || old.end != end || old.color != color;
}
