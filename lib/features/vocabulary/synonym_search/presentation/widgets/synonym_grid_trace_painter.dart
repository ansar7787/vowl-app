import 'package:flutter/material.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Custom painter rendering the active connected drag/tap path across grid cells.
///
/// Wrapped inside a [RepaintBoundary] in [SynonymWordGridBoard] so trace
/// updates do not force expensive parent repaints.
class SynonymGridTracePainter extends CustomPainter {
  final List<int> activePath;
  final int columns;
  final double cellSize;
  final double spacing;
  final Color traceColor;
  final bool isSuccessFlash;

  const SynonymGridTracePainter({
    required this.activePath,
    required this.columns,
    required this.cellSize,
    required this.spacing,
    required this.traceColor,
    required this.isSuccessFlash,
  });

  Offset _centerOf(int index) {
    final row = index ~/ columns;
    final col = index % columns;
    final step = cellSize + spacing;
    return Offset(col * step + cellSize / 2, row * step + cellSize / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (activePath.isEmpty) return;

    final Color activeStroke = isSuccessFlash
        ? AppColors.emerald500
        : traceColor;

    final points = <Offset>[for (final idx in activePath) _centerOf(idx)];

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      final glowPaint = Paint()
        ..color = activeStroke.withValues(alpha: 0.24)
        ..strokeWidth = cellSize * 0.42
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);

      final linePaint = Paint()
        ..color = activeStroke.withValues(alpha: 0.85)
        ..strokeWidth = cellSize * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }

    final nodePaint = Paint()
      ..color = activeStroke.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    for (final pt in points) {
      canvas.drawCircle(pt, cellSize * 0.10, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SynonymGridTracePainter oldDelegate) {
    return oldDelegate.activePath != activePath ||
        oldDelegate.columns != columns ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.spacing != spacing ||
        oldDelegate.traceColor != traceColor ||
        oldDelegate.isSuccessFlash != isSuccessFlash;
  }
}
