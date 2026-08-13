import 'package:flutter/material.dart';

/// Per-segment path painter for the Modern Category Map.
///
/// Draws the incoming path (from previous segment boundary to this node's center)
/// and the outgoing path (from this node's center to the next segment boundary).
///
/// Midpoint continuity math guarantees 100% seamless alignment between
/// adjacent SliverList items without gaps or control-point mismatches.
class ModernSegmentPathPainter extends CustomPainter {
  final Offset currentPoint;
  final Offset? nextPoint;
  final Offset? prevPoint;
  final Color activeColor;
  final bool isCompleted;
  final bool isPrevCompleted;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final bool isTollGate;
  final double glowPulse;

  const ModernSegmentPathPainter({
    required this.currentPoint,
    this.nextPoint,
    this.prevPoint,
    required this.activeColor,
    required this.isCompleted,
    required this.isPrevCompleted,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    this.isTollGate = false,
    this.glowPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double nodeX = currentPoint.dx;
    final double centerY = size.height / 2;
    final double lockedAlpha = isDark ? 0.15 : 0.10;

    // ── Header connection (level 1 top connection) ──
    if (isFirst) {
      final topCenter = Offset(size.width / 2, 0);
      canvas.drawCircle(topCenter, 6.0, Paint()..color = activeColor);

      final headerPath = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..cubicTo(
          topCenter.dx,
          centerY * 0.4,
          nodeX,
          centerY * 0.6,
          nodeX,
          centerY,
        );

      final isActive = isPrevCompleted;
      canvas.drawPath(
        headerPath,
        Paint()
          ..color = isActive ? activeColor : activeColor.withValues(alpha: lockedAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round,
      );

      if (isActive) {
        canvas.drawPath(
          headerPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.25)
            ..strokeWidth = 14.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
        );
      }
    }

    // ── Incoming path from top boundary (y=0) to node center (y=centerY) ──
    if (!isFirst && prevPoint != null) {
      final prevX = prevPoint!.dx;
      final midX = (prevX + nodeX) / 2;

      final incomingPath = Path()
        ..moveTo(midX, 0)
        ..cubicTo(
          midX,
          centerY * 0.35,
          nodeX,
          centerY * 0.65,
          nodeX,
          centerY,
        );

      final isActive = isPrevCompleted;
      canvas.drawPath(
        incomingPath,
        Paint()
          ..color = isActive ? activeColor : activeColor.withValues(alpha: lockedAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round,
      );

      if (isActive) {
        canvas.drawPath(
          incomingPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.25)
            ..strokeWidth = 14.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
        );
      }
    }

    // ── Outgoing path from node center (y=centerY) to bottom boundary (y=size.height) ──
    if (!isLast && nextPoint != null) {
      final nextX = nextPoint!.dx;
      final midX = (nodeX + nextX) / 2;
      final bottomY = size.height;
      final remainingH = bottomY - centerY;

      final outgoingPath = Path()
        ..moveTo(nodeX, centerY)
        ..cubicTo(
          nodeX,
          centerY + remainingH * 0.35,
          midX,
          centerY + remainingH * 0.65,
          midX,
          bottomY,
        );

      final isActive = isCompleted;

      if (isTollGate) {
        _drawDashedPath(
          canvas,
          outgoingPath,
          Paint()
            ..color = Colors.amber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.0
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawPath(
          outgoingPath,
          Paint()
            ..color = isActive ? activeColor : activeColor.withValues(alpha: lockedAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.0
            ..strokeCap = StrokeCap.round,
        );

        if (isActive) {
          canvas.drawPath(
            outgoingPath,
            Paint()
              ..color = activeColor.withValues(alpha: 0.25)
              ..strokeWidth = 14.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
          );
        }
      }
    }

    // ── Current node subtle beacon glow ──
    if (glowPulse > 0.0) {
      final pulseRadius = 46.0 + 8.0 * glowPulse;
      canvas.drawCircle(
        Offset(nodeX, centerY),
        pulseRadius,
        Paint()
          ..color = activeColor.withValues(alpha: 0.25 * (1.0 - glowPulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 12.0;
    const dashSpace = 8.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ModernSegmentPathPainter oldDelegate) {
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isPrevCompleted != isPrevCompleted ||
        oldDelegate.isDark != isDark ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isTollGate != isTollGate ||
        oldDelegate.glowPulse != glowPulse ||
        oldDelegate.currentPoint != currentPoint ||
        oldDelegate.nextPoint != nextPoint ||
        oldDelegate.prevPoint != prevPoint;
  }
}
