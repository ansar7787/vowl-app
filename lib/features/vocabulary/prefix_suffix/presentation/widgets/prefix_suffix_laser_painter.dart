import 'package:flutter/material.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Custom painter for real-time laser swipe trail in PrefixSuffixPrecisionSlicer.
class PrefixSuffixLaserPainter extends CustomPainter {
  final Offset? start;
  final Offset? current;
  final bool isWrong;

  static final _corePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  PrefixSuffixLaserPainter({
    this.start,
    this.current,
    this.isWrong = false,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;
    final color = isWrong ? AppColors.red500 : AppColors.indigo500;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start!, current!, glow);
    canvas.drawLine(start!, current!, _corePaint);
  }

  @override
  bool shouldRepaint(covariant PrefixSuffixLaserPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.current != current ||
      oldDelegate.isWrong != isWrong;
}
