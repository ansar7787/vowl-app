import 'package:vowl/core/theme/app_colors.dart';
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
    final validIndices = selectedIndices
        .where((idx) => idx >= 0 && idx < starOffsets.length)
        .toList();
    if (validIndices.length < 2) return;

    Color lineColor = themeColor;
    if (isAnswered) {
      lineColor = (isCorrect ?? false)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    final Paint paint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 3.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.2 + (0.15 * pulseValue))
      ..strokeWidth = 8.w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final Offset start = starOffsets[validIndices.first];
    path.moveTo(start.dx, start.dy);

    for (int i = 1; i < validIndices.length; i++) {
      final Offset target = starOffsets[validIndices[i]];
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

    for (int idx in validIndices) {
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
