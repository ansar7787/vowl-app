import 'package:flutter/material.dart';

class FixTheSentenceScratchOverlayPainter extends CustomPainter {
  final List<Offset> points;

  FixTheSentenceScratchOverlayPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var p in points) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);

      // Simple kinetic particle effect (dust)
      final particlePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      // Draw a few small particles around the last few points
      final recentPoints = points.reversed.take(5).toList();
      for (var i = 0; i < recentPoints.length; i++) {
        final p = recentPoints[i];
        final offset = Offset((i % 3 - 1) * 8.0, (i % 2 == 0 ? -1 : 1) * 6.0);
        canvas.drawCircle(p + offset, i % 2 == 0 ? 2 : 1.5, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant FixTheSentenceScratchOverlayPainter oldDelegate,
  ) {
    return true; // The list is mutated in-place, so we must always repaint on rebuild
  }
}
