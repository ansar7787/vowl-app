import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentinelNeedlePainter extends CustomPainter {
  final Color color;
  final bool isGlass;

  SentinelNeedlePainter({required this.color, required this.isGlass});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // 1. Shadow/Outer Frame Glow
    if (isGlass) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(_getOuterFramePath(size), glowPaint);
    }

    // 2. Main Segmented Frame
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isGlass ? 0.8 : 0.4),
          color.withValues(alpha: isGlass ? 0.3 : 0.1),
          color.withValues(alpha: isGlass ? 0.6 : 0.2),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(_getOuterFramePath(size), framePaint);

    // 3. Crystalline Energy Core (The "Sentinel" Beam)
    if (isGlass) {
      final corePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromLTWH(centerX - 5.r, 0, 10.r, size.height * 0.8))
        ..style = PaintingStyle.fill;

      final corePath = Path()
        ..moveTo(centerX, size.height * 0.05)
        ..lineTo(centerX + 3.r, size.height * 0.4)
        ..lineTo(centerX + 1.r, size.height * 0.75)
        ..lineTo(centerX - 1.r, size.height * 0.75)
        ..lineTo(centerX - 3.r, size.height * 0.4)
        ..close();

      canvas.drawPath(corePath, corePaint);
    }

    // 4. Refractive Edge Highlights
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: isGlass ? 0.4 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(_getOuterFramePath(size), edgePaint);

    // 5. Precision Micro-Ticks (The "Instrument" Look)
    if (isGlass) {
      final tickPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      for (int i = 1; i <= 5; i++) {
        final y = size.height * (0.3 + (i * 0.08));
        final tickWidth = (i == 3) ? 6.r : 3.r;
        canvas.drawLine(
          Offset(centerX - tickWidth, y),
          Offset(centerX + tickWidth, y),
          tickPaint,
        );
      }
    }
  }

  Path _getOuterFramePath(Size size) {
    final centerX = size.width / 2;
    return Path()
      ..moveTo(centerX, 0) // Tip
      ..lineTo(size.width, size.height * 0.35) // Flare
      ..lineTo(centerX + 6.r, size.height * 0.45) // Neck In
      ..lineTo(centerX + 8.r, size.height * 0.8) // Base Flare
      ..lineTo(centerX - 8.r, size.height * 0.8) // Base Flare
      ..lineTo(centerX - 6.r, size.height * 0.45) // Neck In
      ..lineTo(0, size.height * 0.35) // Flare
      ..close();
  }

  @override
  bool shouldRepaint(covariant SentinelNeedlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isGlass != isGlass;
  }
}
