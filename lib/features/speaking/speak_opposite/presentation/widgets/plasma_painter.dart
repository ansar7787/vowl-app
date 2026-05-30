import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PlasmaPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final bool isListening;
  final double time;

  PlasmaPainter({
    required this.progress,
    required this.primaryColor,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw central conduit pathway
    final Paint conduitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width / 2, 10.h), Offset(size.width / 2, size.height - 10.h), conduitPaint);

    // Draw charging base poles (Top and Bottom hubs)
    final Paint hubPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r;

    // Top Positive Hub aura
    hubPaint.color = Colors.redAccent.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width / 2, 10.h), 14.r + math.sin(time * 4) * 2.r, hubPaint);
    hubPaint.color = Colors.redAccent;
    canvas.drawCircle(Offset(size.width / 2, 10.h), 6.r, hubPaint..style = PaintingStyle.fill);

    // Bottom Negative Hub aura
    final Color bottomHubColor = Color.lerp(Colors.cyanAccent.withValues(alpha: 0.3), Colors.cyanAccent, progress)!;
    hubPaint.color = bottomHubColor.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width / 2, size.height - 10.h), 14.r + math.cos(time * 4) * 2.r, hubPaint..style = PaintingStyle.stroke);
    hubPaint.color = bottomHubColor;
    canvas.drawCircle(Offset(size.width / 2, size.height - 10.h), 6.r, hubPaint..style = PaintingStyle.fill);

    // Draw active electromagnetic plasma arcs
    if (progress > 0) {
      final Paint plasmaPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.8)
        ..strokeWidth = 4.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.r);

      final Paint corePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5.w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path plasmaPath = Path();
      plasmaPath.moveTo(size.width / 2, 10.h);

      // Generate crackling high-voltage displacement steps
      final double totalHeight = size.height - 20.h;
      final double currentHeight = totalHeight * progress;
      final int steps = 14;

      for (int i = 1; i <= steps; i++) {
        final double stepProgress = i / steps;
        if (stepProgress > progress) break;

        final double y = 10.h + totalHeight * stepProgress;
        // Generate high frequency electrical noise
        final double noise = isListening
            ? (math.sin(time * 25.0 + i) * 16.w * math.Random().nextDouble())
            : (math.sin(time * 12.0 + i) * 6.w);

        plasmaPath.lineTo(size.width / 2 + noise, y);
      }

      canvas.drawPath(plasmaPath, plasmaPaint);
      canvas.drawPath(plasmaPath, corePaint);

      // Draw sliding plasma spark capsule
      final Offset sparkCenter = Offset(
        size.width / 2 + (isListening ? math.sin(time * 30) * 4.w : 0),
        10.h + currentHeight,
      );

      final Paint sparkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final Paint sparkGlow = Paint()
        ..color = Colors.cyanAccent
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.r);

      canvas.drawCircle(sparkCenter, 15.r, sparkGlow);
      canvas.drawCircle(sparkCenter, 8.r, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PlasmaPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}
