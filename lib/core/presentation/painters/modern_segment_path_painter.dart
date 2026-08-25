import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Per-segment path painter for the Modern Category Map.
///
/// Draws a thick, rich, 3D-shadowed path line with exact midpoint continuity math.
/// Guarantees 100% seamless alignment between adjacent SliverList items.
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
    const double strokeW = 12.0;
    final double lockedAlpha = isDark ? 0.08 : 0.05;

    // ── Header connection (level 1 top connection) ──
    if (isFirst) {
      // Reaches up across the 10.h padding gap to perfectly touch the bottom of the header card
      final double headerGap = -14.h;
      final topCenter = Offset(size.width / 2, headerGap);
      canvas.drawCircle(topCenter, 8.0, Paint()..color = activeColor);

      final headerPath = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..cubicTo(
          topCenter.dx,
          centerY * 0.50,
          nodeX,
          centerY * 0.50,
          nodeX,
          centerY,
        );

      final isActive = isPrevCompleted;

      canvas.drawPath(
        headerPath,
        Paint()
          ..color = isActive
              ? activeColor
              : activeColor.withValues(alpha: lockedAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      if (isActive) {
        canvas.drawPath(
          headerPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.35)
            ..strokeWidth = strokeW + 8.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );
      }
    }

    // ── Incoming path from top boundary (y=0) to node center (y=centerY) ──
    //
    // S-curve math: cp1 anchors horizontally near the *source* X and cp2
    // near the *destination* X. This makes the path lazily leave the
    // previous node before sweeping into the current one — a proper
    // S-shape rather than a stiff kink.
    if (!isFirst && prevPoint != null) {
      final prevX = prevPoint!.dx;
      final midX = (prevX + nodeX) / 2;

      final incomingPath = Path()
        ..moveTo(midX, 0)
        ..cubicTo(
          midX,              // cp1.x — hold at the hand-off X
          centerY * 0.35,    // cp1.y — drop 35% vertically first
          nodeX,             // cp2.x — swing to destination X
          centerY * 0.65,    // cp2.y — arrive from above
          nodeX,
          centerY,
        );

      final isActive = isPrevCompleted;

      canvas.drawPath(
        incomingPath,
        Paint()
          ..color = isActive
              ? activeColor
              : activeColor.withValues(alpha: lockedAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );

      if (isActive) {
        canvas.drawPath(
          incomingPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.35)
            ..strokeWidth = strokeW + 8.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );
      }
    }

    // ── Outgoing path from node center (y=centerY) to bottom boundary (y=size.height) ──
    //
    // Mirror of the incoming S-curve logic: cp1 holds at the current
    // node's X while dropping vertically, then cp2 swings to the hand-off
    // X that becomes the next segment's start.
    if (!isLast && nextPoint != null) {
      final nextX = nextPoint!.dx;
      final midNextX = (nodeX + nextX) / 2;
      final bottomY = size.height;
      final remainingH = bottomY - centerY;

      final outgoingPath = Path()
        ..moveTo(nodeX, centerY)
        ..cubicTo(
          nodeX,                             // cp1.x — hold at current X
          centerY + remainingH * 0.35,       // cp1.y — descend 35%
          midNextX,                          // cp2.x — swing toward hand-off
          centerY + remainingH * 0.65,       // cp2.y — arrive from the side
          midNextX,
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
            ..strokeWidth = 8.0
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawPath(
          outgoingPath,
          Paint()
            ..color = isActive
                ? activeColor
                : activeColor.withValues(alpha: lockedAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.butt,
        );

        if (isActive) {
          canvas.drawPath(
            outgoingPath,
            Paint()
              ..color = activeColor.withValues(alpha: 0.35)
              ..strokeWidth = strokeW + 8.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
          );
        }
      }
    }

    // ── Current node subtle beacon glow ──
    if (glowPulse > 0.0) {
      final pulseRadius = 50.0 + 8.0 * glowPulse;
      canvas.drawCircle(
        Offset(nodeX, centerY),
        pulseRadius,
        Paint()
          ..color = activeColor.withValues(alpha: 0.28 * (1.0 - glowPulse))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 14.0;
    const dashSpace = 10.0;
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
