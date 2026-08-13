import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SegmentPathPainter extends CustomPainter {
  final Color incomingColor;
  final Color outgoingColor;
  final double currentOffset;
  final double nextOffset;
  final bool isLast;
  final int level;
  final double pathProgress; // 0.0 → 1.0: animated path draw progress
  final bool isCurrent;
  final double glowPulse; // 0.0 → 1.0: glow pulse for current node path

  SegmentPathPainter({
    required this.incomingColor,
    required this.outgoingColor,
    required this.currentOffset,
    required this.nextOffset,
    required this.isLast,
    required this.level,
    this.pathProgress = 1.0,
    this.isCurrent = false,
    this.glowPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = currentOffset + 50.r;
    final double endX = nextOffset + 50.r;
    final double centerY = size.height / 2;

    final incomingPath = Path();

    if (level == 1) {
      // 1. Clean Connection from Dashboard (reaching up to touch the header)
      final double headerGap = -30.h;

      incomingPath.moveTo(size.width / 2, headerGap);
      incomingPath.lineTo(startX, centerY);
    } else {
      // 2. Continuous Path from previous level
      incomingPath.moveTo(startX, 0);
      incomingPath.lineTo(startX, centerY);
    }

    final outgoingPath = Path();
    if (!isLast) {
      outgoingPath.moveTo(startX, centerY);
      // 3. Smooth Modern Curve to next level
      final midY = centerY + (size.height - centerY) * 0.5;
      outgoingPath.cubicTo(
          startX, centerY + 50.h, endX, midY - 50.h, endX, size.height);
    }

    // Subtle Shadow for the lines
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.r
      ..strokeCap = StrokeCap.butt
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r);

    canvas.drawPath(incomingPath, shadowPaint);
    if (!isLast) {
      canvas.drawPath(outgoingPath, shadowPaint);
    }

    // ── Incoming Path ──
    final incomingPaint = Paint()
      ..color = incomingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.r
      ..strokeCap = StrokeCap.butt;

    canvas.drawPath(incomingPath, incomingPaint);

    // ── Outgoing Path with animated draw ──
    if (!isLast) {
      // Create a clipped version of the outgoing path based on pathProgress
      final pathMetrics = outgoingPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extractedPath =
            metric.extractPath(0, metric.length * pathProgress);

        // If this is the "just-unlocked" path, draw a glow underneath
        if (glowPulse > 0.0) {
          final glowPaint = Paint()
            ..color = outgoingColor.withValues(alpha: 0.3 * glowPulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = (14.r + 12.r * glowPulse)
            ..strokeCap = StrokeCap.butt
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.r * glowPulse);
          canvas.drawPath(extractedPath, glowPaint);
        }

        final outgoingPaint = Paint()
          ..color = outgoingColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14.r
          ..strokeCap = StrokeCap.butt;
        canvas.drawPath(extractedPath, outgoingPaint);

        // Sparkle dot at the tip of the animated path
        if (pathProgress < 1.0 && pathProgress > 0.0) {
          final tangent = metric.getTangentForOffset(metric.length * pathProgress);
          if (tangent != null) {
            final tipPaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);
            canvas.drawCircle(tangent.position, 8.r, tipPaint);

            final dotPaint = Paint()
              ..color = outgoingColor
              ..style = PaintingStyle.fill;
            canvas.drawCircle(tangent.position, 5.r, dotPaint);
          }
        }
      }
    }

    // ── Current-Node glow ring at the node center ──
    if (isCurrent && glowPulse > 0.0) {
      final glowPaint = Paint()
        ..color = incomingColor.withValues(alpha: 0.25 * glowPulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.r
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r * glowPulse);
      canvas.drawCircle(Offset(startX, centerY), 55.r, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SegmentPathPainter oldDelegate) {
    return oldDelegate.incomingColor != incomingColor ||
        oldDelegate.outgoingColor != outgoingColor ||
        oldDelegate.currentOffset != currentOffset ||
        oldDelegate.nextOffset != nextOffset ||
        oldDelegate.level != level ||
        oldDelegate.pathProgress != pathProgress ||
        oldDelegate.isCurrent != isCurrent ||
        oldDelegate.glowPulse != glowPulse;
  }
}
