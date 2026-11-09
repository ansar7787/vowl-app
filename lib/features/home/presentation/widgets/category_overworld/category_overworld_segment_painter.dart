import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dual-Tone Luminous Catmull-Rom S-curve path painter for the Category Overworld Map.
/// Draws a unified, continuous adventure highway from the Mastery Card through all game realms:
/// - Outer Track Bed (16px): Soft, translucent category foundation framing the road.
/// - Inner Luminous Core (6px): Punchy, vibrant category energy stream — 100% alive, zero dullness.
/// Eliminates patchy color fragmentation and delivers the AAA game overworld standard.
class CategoryOverworldSegmentPainter extends CustomPainter {
  final Offset currentPoint;
  final Offset? nextPoint;
  final Offset? prevPoint;

  final Color themeColor;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final bool isMidnight;

  const CategoryOverworldSegmentPainter({
    required this.currentPoint,
    this.nextPoint,
    this.prevPoint,
    required this.themeColor,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    this.isMidnight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double nodeX = currentPoint.dx;
    final double centerY = size.height / 2;

    const double outerStrokeW = 16.0;
    const double innerStrokeW = 6.0;

    // ── Dual-Tone Luminous Highway Color System ──────────────────────────────
    // 1. Outer Track Bed: Soft, translucent framing defining the roadbed.
    final Color bedColor = isDark
        ? themeColor.withValues(alpha: isMidnight ? 0.22 : 0.20)
        : themeColor.withValues(alpha: 0.18);

    // 2. Inner Luminous Core: Vibrant, punchy category stream.
    // Confident, awake, and 100% active — completely eliminates the "dull / unplayed" ghost feel.
    final Color coreColor = isDark
        ? themeColor.withValues(alpha: 0.85)
        : themeColor.withValues(alpha: 0.80);

    final bedPaint = Paint()
      ..color = bedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── 1. Top Connection: Vertical drop from Mastery Card center, then sweeping to Node 0 ────
    if (isFirst) {
      final double headerGap = -14.h;
      final topCenter = Offset(size.width / 2, headerGap);

      // Clean concentric anchor socket at Mastery Card bottom center
      canvas.drawCircle(topCenter, 7.0, Paint()..color = bedColor);
      canvas.drawCircle(topCenter, 3.5, Paint()..color = coreColor);

      // Straight vertical line down, then smooth sweep outward into Node 0
      final headerPath = Path()
        ..moveTo(topCenter.dx, topCenter.dy)
        ..lineTo(topCenter.dx, 14.h)
        ..cubicTo(
          topCenter.dx,
          centerY * 0.45,
          nodeX,
          centerY * 0.45,
          nodeX,
          centerY,
        );

      canvas.drawPath(headerPath, bedPaint);
      canvas.drawPath(headerPath, corePaint);
    }

    // ── 2. Incoming Catmull-Rom Half (y=0 to y=centerY) ─────────────────────
    if (!isFirst && prevPoint != null) {
      final double x0 = prevPoint!.dx;
      final double x1 = nodeX;
      final double midX = (x0 + x1) / 2;

      // Exact de Casteljau split at t=0.5 matching the outgoing half
      final incomingPath = Path()
        ..moveTo(midX, 0)
        ..cubicTo(
          0.25 * x0 + 0.75 * x1,
          size.height * 0.1125,
          x1,
          size.height * 0.225,
          x1,
          centerY,
        );

      canvas.drawPath(incomingPath, bedPaint);
      canvas.drawPath(incomingPath, corePaint);
    }

    // ── 3. Outgoing Catmull-Rom Half (y=centerY to y=size.height) ────────────
    if (!isLast && nextPoint != null) {
      final double x0 = nodeX;
      final double x1 = nextPoint!.dx;
      final double midX = (x0 + x1) / 2;

      // Exact de Casteljau split at t=0.5
      final outgoingPath = Path()
        ..moveTo(x0, centerY)
        ..cubicTo(
          x0,
          centerY + size.height * 0.275,
          0.75 * x0 + 0.25 * x1,
          centerY + size.height * 0.3875,
          midX,
          size.height,
        );

      canvas.drawPath(outgoingPath, bedPaint);
      canvas.drawPath(outgoingPath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CategoryOverworldSegmentPainter oldDelegate) {
    return oldDelegate.currentPoint != currentPoint ||
        oldDelegate.nextPoint != nextPoint ||
        oldDelegate.prevPoint != prevPoint ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isMidnight != isMidnight;
  }
}
