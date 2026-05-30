import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FogPainter extends CustomPainter {
  final double progress;
  final double time;

  FogPainter({
    required this.progress,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.98) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw procedural glass fog background
    final Paint fogPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.92),
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.88),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.r;

    // Apply frosted blur effect
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(28.r)),
      fogPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(28.r)),
      borderPaint,
    );

    // Procedural Wiping: Clear canvas from left to right based on wipe progress
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;
    
    final path = Path();
    final double step = size.width * progress;

    if (progress > 0) {
      path.moveTo(0, 0);
      path.lineTo(step, 0);
      
      // Crackling water condensation boundary
      for (double y = 0; y <= size.height; y += 8.h) {
        final double wave = math.sin(time * 24.0 + y * 0.15) * 5.w;
        path.lineTo(step + wave, y);
      }
      
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, clearPaint);

      // Draw sparkling condensation water droplets along the boundary
      final Paint dropletGlow = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.w
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.r);

      final Paint dropletCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2.w;

      final Path dropletPath = Path();
      dropletPath.moveTo(step, 0);
      for (double y = 0; y <= size.height; y += 6.h) {
        final double wave = math.sin(time * 24.0 + y * 0.15) * 5.w;
        dropletPath.lineTo(step + wave, y);
      }

      canvas.drawPath(dropletPath, dropletGlow);
      canvas.drawPath(dropletPath, dropletCore);
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.time != time;
  }
}
