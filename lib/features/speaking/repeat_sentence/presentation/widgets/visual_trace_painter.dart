import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VisualTracePainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final Color themeColor;
  final List<double> amplitudes;

  VisualTracePainter({
    required this.progress,
    required this.isListening,
    required this.themeColor,
    required this.amplitudes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    // 1. Draw static background soundwave guide
    final Paint guidePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.1)
      ..strokeWidth = 2.w
      ..style = PaintingStyle.stroke;

    final Path guidePath = Path();
    guidePath.moveTo(0, midY);

    const int points = 60;
    for (int i = 0; i <= points; i++) {
      final double x = (width / points) * i;
      final double amp = amplitudes.length > i ? amplitudes[i] : 16.0;
      final double y = midY + math.sin(i * 0.3) * amp;
      guidePath.lineTo(x, y);
    }
    canvas.drawPath(guidePath, guidePaint);

    // 2. Draw live active glowing vocal trace path
    if (progress > 0) {
      final Paint activePaint = Paint()
        ..color = themeColor
        ..strokeWidth = 4.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path activePath = Path();
      activePath.moveTo(0, midY);

      final double currentLimitX = width * progress;
      for (double x = 0; x <= currentLimitX; x += 2.w) {
        final double ratio = x / width;
        final int index = (ratio * points).floor();
        final double amp = amplitudes.length > index ? amplitudes[index] : 16.0;
        
        // Add random microphone flutter while recording
        final double flutter = isListening ? (math.sin(x * 0.1 + DateTime.now().millisecondsSinceEpoch * 0.05) * 4.h) : 0;
        final double y = midY + math.sin(ratio * points * 0.3) * (amp + flutter);
        activePath.lineTo(x, y);
      }

      canvas.drawPath(activePath, activePaint);
      canvas.drawPath(activePath, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VisualTracePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}
