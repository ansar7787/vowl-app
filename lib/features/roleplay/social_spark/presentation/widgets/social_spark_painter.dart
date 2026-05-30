import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConstellationPainter extends CustomPainter {
  final List<int> selectedIndices;
  final List<Offset> starOffsets;
  final Color themeColor;
  final bool isAnswered;
  final bool? isCorrect;
  final double pulseValue;

  ConstellationPainter({
    required this.selectedIndices,
    required this.starOffsets,
    required this.themeColor,
    required this.isAnswered,
    this.isCorrect,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndices.length < 2) return;

    Color lineColor = themeColor;
    if (isAnswered) {
      lineColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    }

    final Paint paint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.2 + (0.15 * pulseValue))
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final Offset start = starOffsets[selectedIndices.first];
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i < selectedIndices.length; i++) {
      final Offset target = starOffsets[selectedIndices[i]];
      path.lineTo(target.dx, target.dy);
    }

    // Draw background glowing aura path
    canvas.drawPath(path, glowPaint);
    // Draw crisp front path
    canvas.drawPath(path, paint);

    // Draw little cosmic telemetry sparks at connecting hubs
    final Paint sparkPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int idx in selectedIndices) {
      canvas.drawCircle(starOffsets[idx], 4.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.starOffsets != starOffsets ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isAnswered != isAnswered ||
        oldDelegate.isCorrect != isCorrect ||
        oldDelegate.pulseValue != pulseValue;
  }
}
