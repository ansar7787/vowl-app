import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SegmentPathPainter extends CustomPainter {
  final Color color;
  final double currentOffset;
  final double nextOffset;
  final bool isLast;
  final int level;

  SegmentPathPainter({
    required this.color,
    required this.currentOffset,
    required this.nextOffset,
    required this.isLast,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isLast) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.r
      ..strokeCap = StrokeCap.round;

    final double startX = currentOffset + 50.r;
    final double endX = nextOffset + 50.r;
    final double centerY = size.height / 2;

    final path = Path();

    if (level == 1) {
      // 1. Clean Connection from Dashboard
      canvas.drawCircle(
        Offset(size.width / 2, 0),
        10.r,
        Paint()..color = Colors.white,
      );

      path.moveTo(size.width / 2, 0);
      path.lineTo(startX, centerY);
    } else {
      // 2. Continuous Path
      path.moveTo(startX, 0);
      path.lineTo(startX, centerY);
    }

    // 3. Smooth Modern Curve
    final midY = centerY + (size.height - centerY) * 0.5;

    path.cubicTo(startX, centerY + 50.h, endX, midY - 50.h, endX, size.height);

    // Subtle Shadow for the line
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.r
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SegmentPathPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.currentOffset != currentOffset ||
        oldDelegate.nextOffset != nextOffset ||
        oldDelegate.level != level;
  }
}
