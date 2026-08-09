import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SegmentPathPainter extends CustomPainter {
  final Color incomingColor;
  final Color outgoingColor;
  final double currentOffset;
  final double nextOffset;
  final bool isLast;
  final int level;

  SegmentPathPainter({
    required this.incomingColor,
    required this.outgoingColor,
    required this.currentOffset,
    required this.nextOffset,
    required this.isLast,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = currentOffset + 50.r;
    final double endX = nextOffset + 50.r;
    final double centerY = size.height / 2;

    final incomingPath = Path();

    if (level == 1) {
      // 1. Clean Connection from Dashboard
      canvas.drawCircle(
        Offset(size.width / 2, 0),
        10.r,
        Paint()..color = Colors.white,
      );

      incomingPath.moveTo(size.width / 2, 0);
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
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r);

    canvas.drawPath(incomingPath, shadowPaint);
    if (!isLast) {
      canvas.drawPath(outgoingPath, shadowPaint);
    }

    final incomingPaint = Paint()
      ..color = incomingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.r
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(incomingPath, incomingPaint);

    if (!isLast) {
      final outgoingPaint = Paint()
        ..color = outgoingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.r
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(outgoingPath, outgoingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SegmentPathPainter oldDelegate) {
    return oldDelegate.incomingColor != incomingColor ||
        oldDelegate.outgoingColor != outgoingColor ||
        oldDelegate.currentOffset != currentOffset ||
        oldDelegate.nextOffset != nextOffset ||
        oldDelegate.level != level;
  }
}
