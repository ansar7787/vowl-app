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
  final double? prevPrevX;
  final double? nextNextX;
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
    this.prevPrevX,
    this.nextNextX,
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
    const double strokeW = 18.0;
    
    // Instead of a barely-visible 5% opacity, we use a solid structural grey
    // to make the locked path look like a real, physical "unpaved road".
    final Color lockedColor = isDark 
        ? const Color(0xFF374151) 
        : const Color(0xFFE5E7EB);

    // ── Header connection (level 1 top connection) ──
    if (isFirst) {
      // Reaches up across the 10.h padding gap to perfectly touch the bottom of the header card
      final double headerGap = -14.h;
      final topCenter = Offset(size.width / 2, headerGap);
      canvas.drawCircle(topCenter, 8.0, Paint()..color = activeColor);

      // The user requested a clean, straight diagonal line pulling from the header 
      // rather than a boring curve.
      final headerPath = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..lineTo(nodeX, centerY);

      final isActive = isPrevCompleted;

      canvas.drawPath(
        headerPath,
        Paint()
          ..color = isActive
              ? activeColor
              : lockedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );

      if (isActive) {
        canvas.drawPath(
          headerPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.35)
            ..strokeWidth = strokeW + 12.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );
      }
    }


    // ── Incoming path from top boundary (y=0) to node center (y=centerY) ──
    //
    // Uses a mathematically exact split of a Catmull-Rom spline. 
    // This is the TRUE INDUSTRY STANDARD. It allows the path to flow naturally 
    // diagonally through center nodes, completely eliminating artificial Z-kinks.
    if (!isFirst && prevPoint != null) {
      final x0 = prevPoint!.dx;
      final x1 = nodeX;
      
      // Calculate smooth natural tangents based on the neighbors
      final t0 = (x1 - (prevPrevX ?? x0)) / 2;
      final t1 = ((nextPoint?.dx ?? x1) - x0) / 2;
      
      // PERFECT MATHEMATICAL SPLIT at t=0.5
      final startX = 0.5 * x0 + 0.5 * x1 + (t0 - t1) / 8;

      final incomingPath = Path()
        ..moveTo(startX, 0)
        ..cubicTo(
          0.25 * x0 + 0.75 * x1 + t0 / 12 - t1 / 6,    // cp1.x
          centerY * 0.333333,                          // cp1.y 
          x1 - t1 / 6,                                 // cp2.x 
          centerY * 0.666667,                          // cp2.y 
          x1,
          centerY,
        );

      final isActive = isPrevCompleted;

      canvas.drawPath(
        incomingPath,
        Paint()
          ..color = isActive
              ? activeColor
              : lockedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );

      if (isActive) {
        canvas.drawPath(
          incomingPath,
          Paint()
            ..color = activeColor.withValues(alpha: 0.35)
            ..strokeWidth = strokeW + 12.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );
      }
    }

    // ── Outgoing path from node center (y=centerY) to bottom boundary (y=size.height) ──
    //
    // The exact mirror of the Catmull-Rom incoming path.
    if (!isLast && nextPoint != null) {
      final x0 = prevPoint?.dx ?? nodeX;
      final x1 = nodeX;
      final x2 = nextPoint!.dx;
      
      final t1 = (x2 - x0) / 2;
      final t2 = ((nextNextX ?? x2) - x1) / 2;
      
      // PERFECT MATHEMATICAL SPLIT at t=0.5
      final endX = 0.5 * x1 + 0.5 * x2 + (t1 - t2) / 8;
      final bottomY = size.height;

      final outgoingPath = Path()
        ..moveTo(x1, centerY)
        ..cubicTo(
          x1 + t1 / 6,                                 // cp1.x 
          centerY * 1.333333,                          // cp1.y 
          0.75 * x1 + 0.25 * x2 + t1 / 6 - t2 / 12,    // cp2.x 
          centerY * 1.666667,                          // cp2.y 
          endX,
          bottomY,
        );

      final isActive = isCompleted;

      if (isTollGate) {
        _drawDashedPath(
          canvas,
          outgoingPath,
          Paint()
            ..color = isActive
                ? activeColor
                : lockedColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.butt,
        );

        if (isActive) {
          _drawDashedPath(
            canvas,
            outgoingPath,
            Paint()
              ..color = activeColor.withValues(alpha: 0.35)
              ..strokeWidth = strokeW + 12.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
          );
        }
      } else {
        canvas.drawPath(
          outgoingPath,
          Paint()
            ..color = isActive
                ? activeColor
                : lockedColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.butt,
        );

        if (isActive) {
          canvas.drawPath(
            outgoingPath,
            Paint()
              ..color = activeColor.withValues(alpha: 0.35)
              ..strokeWidth = strokeW + 12.0
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
    const dashWidth = 24.0;
    const dashSpace = 16.0;
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
