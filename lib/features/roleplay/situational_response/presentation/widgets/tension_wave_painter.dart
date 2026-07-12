import 'package:flutter/material.dart';

class TensionWavePainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final Color themeColor;
  final bool isAnswered;
  final bool? isCorrect;

  TensionWavePainter({
    required this.progress,
    required this.pulseValue,
    required this.themeColor,
    required this.isAnswered,
    this.isCorrect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    Color waveColor = themeColor;
    if (isAnswered) {
      waveColor = (isCorrect ?? false) ? Colors.greenAccent : Colors.redAccent;
    } else {
      // Transition from cyan/blue to red based on time/tension progress
      waveColor =
          Color.lerp(themeColor, const Color(0xFFFF3366), progress) ??
          themeColor;
    }

    final wavePaint = Paint()
      ..color = waveColor.withValues(alpha: 0.08 + (0.1 * progress))
      ..style = PaintingStyle.fill;

    // Pulse circles
    canvas.drawCircle(
      center,
      baseRadius * (0.8 + 0.15 * pulseValue),
      wavePaint,
    );

    final linePaint = Paint()
      ..color = waveColor.withValues(alpha: 0.2 + (0.3 * progress))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, baseRadius * (0.8 + 0.1 * pulseValue), linePaint);
  }

  @override
  bool shouldRepaint(covariant TensionWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isAnswered != isAnswered ||
        oldDelegate.isCorrect != isCorrect;
  }
}
