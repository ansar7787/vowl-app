import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BloomPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isListening;
  final double time;

  BloomPainter({
    required this.progress,
    required this.primaryColor,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double stemHeight = 40.h;

    // Draw holographic glowing stem
    final Paint stemPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3 + progress * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.r
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(center.dx, size.height)
      ..quadraticBezierTo(
        center.dx + math.sin(time * 3.0) * 10 * progress,
        size.height - stemHeight,
        center.dx,
        center.dy + 15.r,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Glowing base leaves
    final Paint leafPaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.2 + progress * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 20.w, size.height - 20.h),
        width: 25.w * (0.5 + progress * 0.5),
        height: 12.h,
      ),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 20.w, size.height - 20.h),
        width: 25.w * (0.5 + progress * 0.5),
        height: 12.h,
      ),
      leafPaint,
    );

    // Draw glowing petals
    final int numPetals = 8;
    final Paint petalPaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r);

    for (int i = 0; i < numPetals; i++) {
      // Angular spacing
      final double angle = (i * math.pi * 2) / numPetals + (time * 0.1);
      final double petalDist = 38.r * progress;
      final double petalSize =
          (14.r + math.sin(time * 4.0 + i) * 2.r) * (0.4 + progress * 0.6);

      // Color mapping: sleep indigo -> radiant pink-violet bloom
      final Color sleepColor = primaryColor.withValues(alpha: 0.25);
      final Color activeColor = Color.lerp(
        sleepColor,
        const Color(0xFFDD2476),
        progress,
      )!;

      final Offset petalCenter = Offset(
        center.dx + math.cos(angle) * petalDist,
        center.dy + math.sin(angle) * petalDist,
      );

      // Draw petal aura glow
      glowPaint.color = activeColor.withValues(alpha: 0.3 * progress);
      canvas.drawCircle(petalCenter, petalSize + 6.r, glowPaint);

      // Draw solid petal
      petalPaint.color = activeColor;
      canvas.drawCircle(petalCenter, petalSize, petalPaint);

      // Draw internal petal ribbing
      final Paint linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.r;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * (petalDist + petalSize * 0.6),
          center.dy + math.sin(angle) * (petalDist + petalSize * 0.6),
        ),
        linePaint,
      );
    }

    // Glowing core seed
    final Paint corePaint = Paint()
      ..color = Color.lerp(Colors.orangeAccent, Colors.yellowAccent, progress)!
      ..style = PaintingStyle.fill;
    final double coreRadius =
        (12.r + math.sin(time * 5.0) * 1.r) * (0.8 + progress * 0.4);

    // Core Glow
    final Paint coreGlow = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.r);
    canvas.drawCircle(center, coreRadius + 5.r, coreGlow);
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant BloomPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}
