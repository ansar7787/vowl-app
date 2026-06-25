import 'package:flutter/material.dart';

/// Shared dashed-path rendering, extracted from what were two verbatim-identical
/// private `_drawDashedPath` implementations in [GameMapLinePainter] and
/// [ModernPathPainter]. Both painters now delegate here instead of maintaining
/// two copies of the same logic.
void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dashWidth,
  required double dashSpace,
}) {
  double distance = 0.0;

  for (final pathMetric in path.computeMetrics()) {
    while (distance < pathMetric.length) {
      canvas.drawPath(
        pathMetric.extractPath(distance, distance + dashWidth),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
    distance = 0.0;
  }
}
