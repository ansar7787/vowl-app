import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SegmentPathPainter extends CustomPainter {
  final Color incomingColor;
  final Color outgoingColor;
  final double currentOffset;
  final double nextOffset;
  final double prevOffset; // Added to calculate incoming curve from previous node
  final bool isLast;
  final int level;
  final double incomingPathProgress;
  final double outgoingPathProgress;
  final bool isCurrent;
  final Animation<double>? glowAnimation; // 0.0 → 1.0: glow pulse for current node path

  SegmentPathPainter({
    required this.incomingColor,
    required this.outgoingColor,
    required this.currentOffset,
    required this.nextOffset,
    required this.prevOffset,
    required this.isLast,
    required this.level,
    this.incomingPathProgress = 1.0,
    this.outgoingPathProgress = 1.0,
    this.isCurrent = false,
    this.glowAnimation,
  }) : super(repaint: glowAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = currentOffset + 50.r;
    final double endX = nextOffset + 50.r;
    final double prevX = prevOffset + 50.r;
    final double centerY = size.height / 2;

    final incomingPath = Path();

    if (level == 1) {
      // 1. Clean Connection from Dashboard (reaching up to touch the header)
      final double headerGap = -30.h;
      canvas.drawCircle(
        Offset(size.width / 2, headerGap),
        10.r,
        Paint()..color = incomingColor,
      );

      incomingPath.moveTo(size.width / 2, headerGap);
      incomingPath.cubicTo(
        size.width / 2, 0, 
        startX, 0, 
        startX, centerY,
      );
    } else {
      // 2. Continuous Bouncy Curve from previous level
      // The previous segment ended halfway between prevX and startX at the boundary
      final double boundaryX = (prevX + startX) / 2;
      incomingPath.moveTo(boundaryX, 0);
      
      incomingPath.cubicTo(
        boundaryX + (startX - prevX) * 0.25, 
        centerY * 0.5,
        startX, 
        centerY * 0.5,
        startX, 
        centerY,
      );
    }

    final outgoingPath = Path();
    if (!isLast) {
      outgoingPath.moveTo(startX, centerY);
      
      // 3. Smooth Bouncy Curve to next level boundary
      final double boundaryX = (startX + endX) / 2;
      
      outgoingPath.cubicTo(
        startX, 
        centerY + (size.height - centerY) * 0.5,
        boundaryX - (endX - startX) * 0.25, 
        size.height - (size.height - centerY) * 0.5,
        boundaryX, 
        size.height,
      );
    }

    // Subtle Shadow for the lines
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.r
      ..strokeCap = StrokeCap.butt
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r);

    canvas.drawPath(incomingPath, shadowPaint);
    if (!isLast) {
      canvas.drawPath(outgoingPath, shadowPaint);
    }

    // ── Incoming Path with animated draw ──
    final incomingPaint = Paint()
      ..color = incomingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.r
      ..strokeCap = StrokeCap.butt;

    if (incomingPathProgress > 0.0) {
      final pathMetrics = incomingPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extractedPath = metric.extractPath(0, metric.length * incomingPathProgress);
        
        canvas.drawPath(extractedPath, incomingPaint);
        
        final double glowValue = glowAnimation?.value ?? 0.0;
        if (glowValue > 0.0 && incomingPathProgress == 1.0) {
          final glowPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.4 * glowValue)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 22.r - 8.r
            ..strokeCap = StrokeCap.butt;
          canvas.drawPath(extractedPath, glowPaint);
        }
        
        if (incomingPathProgress > 0.0 && incomingPathProgress < 1.0 && isCurrent) {
          final tangent = metric.getTangentForOffset(metric.length * incomingPathProgress);
          if (tangent != null) {
            final tipPaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);
            canvas.drawCircle(tangent.position, 8.r, tipPaint);

            final dotPaint = Paint()
              ..color = Colors.white
              ..style = PaintingStyle.fill;
            canvas.drawCircle(tangent.position, 4.r, dotPaint);
          }
        }
      }
    }

    // ── Outgoing Path with animated draw ──
    if (!isLast) {
      // Create a clipped version of the outgoing path based on pathProgress
      final pathMetrics = outgoingPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extractedPath = metric.extractPath(
          0,
          metric.length * outgoingPathProgress,
        );

        final outgoingPaint = Paint()
          ..color = outgoingColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22.r
          ..strokeCap = StrokeCap.butt;
        canvas.drawPath(extractedPath, outgoingPaint);

        // Sparkle dot at the tip of the animated path
        if (outgoingPathProgress > 0.0 && outgoingPathProgress < 1.0) {
          final tangent = metric.getTangentForOffset(
            metric.length * outgoingPathProgress,
          );
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
    final double glowValue = glowAnimation?.value ?? 0.0;
    if (isCurrent && glowValue > 0.0) {
      final glowPaint = Paint()
        ..color = incomingColor.withValues(alpha: 0.25 * glowValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.r
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r * glowValue);
      canvas.drawCircle(Offset(startX, centerY), 55.r, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SegmentPathPainter oldDelegate) {
    return oldDelegate.incomingColor != incomingColor ||
        oldDelegate.outgoingColor != outgoingColor ||
        oldDelegate.currentOffset != currentOffset ||
        oldDelegate.nextOffset != nextOffset ||
        oldDelegate.prevOffset != prevOffset ||
        oldDelegate.level != level ||
        oldDelegate.incomingPathProgress != incomingPathProgress ||
        oldDelegate.outgoingPathProgress != outgoingPathProgress ||
        oldDelegate.isCurrent != isCurrent ||
        oldDelegate.glowAnimation != glowAnimation;
  }
}
