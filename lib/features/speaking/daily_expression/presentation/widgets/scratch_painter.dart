import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScratchPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final double time;
  final Color primaryColor;

  ScratchPainter({
    required this.progress,
    required this.isListening,
    required this.time,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.98) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.saveLayer(rect, Paint());

    // Draw metallic silver-grey base foil layer
    final Paint foilPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.grey.shade400,
          Colors.grey.shade600,
          Colors.grey.shade500,
          Colors.grey.shade300,
          Colors.grey.shade600,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRect(rect, foilPaint);

    // Draw high-fidelity brushed metal diagonal textures
    final Paint linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.w;

    for (double i = -size.height; i < size.width; i += 12.w) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        linePaint,
      );
    }

    // Procedural Scratching: Clear the canvas based on progress
    final Paint clearPaint = Paint()..blendMode = BlendMode.clear;

    // Create organic scratching path
    final path = Path();
    final double step = size.width * progress;

    if (progress > 0) {
      path.moveTo(0, 0);
      path.lineTo(step, 0);

      // Scratch border turbulence
      for (double y = 0; y <= size.height; y += 10.h) {
        final double wobble = math.sin(time * 30 + y * 0.1) * 8.w;
        path.lineTo(step + wobble, y);
      }

      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, clearPaint);

      // Draw burning neon plasma edge at the scratch boundary
      final Paint boundaryGlow = Paint()
        ..color = primaryColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.w
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.r);

      final Paint boundaryCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.w;

      final Path boundaryPath = Path();
      boundaryPath.moveTo(step, 0);
      for (double y = 0; y <= size.height; y += 8.h) {
        final double wobble = math.sin(time * 30 + y * 0.1) * 8.w;
        boundaryPath.lineTo(step + wobble, y);
      }

      canvas.drawPath(boundaryPath, boundaryGlow);
      canvas.drawPath(boundaryPath, boundaryCore);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}
