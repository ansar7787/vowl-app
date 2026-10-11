import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

/// Paints handwritten strokes with quadratic bezier curve smoothing and single-dot point rendering.
class ChalkSignaturePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Color strokeColor;
  final int revision;

  const ChalkSignaturePainter(this.strokes, this.strokeColor, this.revision);

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.5
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    for (final stroke in strokes) {
      final points = stroke.points;
      if (points.isEmpty) continue;

      if (points.length == 1) {
        // Draw dot for single tap
        canvas.drawCircle(
          Offset(points.first.x, points.first.y),
          3.25,
          dotPaint,
        );
        continue;
      }

      if (points.length == 2) {
        canvas.drawLine(
          Offset(points[0].x, points[0].y),
          Offset(points[1].x, points[1].y),
          strokePaint,
        );
        continue;
      }

      // Smooth path with quadratic Bezier curves
      final path = Path();
      path.moveTo(points.first.x, points.first.y);

      for (int i = 1; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final midX = (current.x + next.x) / 2;
        final midY = (current.y + next.y) / 2;
        path.quadraticBezierTo(current.x, current.y, midX, midY);
      }

      // Connect to the final point
      path.lineTo(points.last.x, points.last.y);

      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ChalkSignaturePainter oldDelegate) {
    return oldDelegate.revision != revision ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokes.length != strokes.length;
  }
}

