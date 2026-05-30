import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThermalGridPainter extends CustomPainter {
  final double heatLevel;
  final bool isListening;
  final double time;

  ThermalGridPainter({
    required this.heatLevel,
    required this.isListening,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    const int rows = 12;
    const int cols = 12;

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Calculate center of each cell
        final double cx = c * cellWidth + cellWidth / 2;
        final double cy = r * cellHeight + cellHeight / 2;

        // Grid distance from center
        final double dx = cx - size.width / 2;
        final double dy = cy - size.height / 2;
        final double distance = math.sqrt(dx * dx + dy * dy);

        // Ripple wave calculation using sine curves
        final double wave = math.sin((distance / 20.0) - (time * 5.0)) * 0.5 + 0.5;

        // Interpolate grid cell sizes and colors
        final double baseSize = 4.0.r;
        final double activeMultiplier = isListening ? (3.0 + wave * 5.0) * (0.3 + heatLevel * 0.7) : 1.0;
        final double finalSize = baseSize * activeMultiplier;

        // Sizzle heat colors: cold cobalt blue -> superheated thermodynamic orange
        final Color coldColor = const Color(0xFF1D2671).withValues(alpha: 0.2);
        final Color hotColor = const Color(0xFFFF5722).withValues(alpha: 0.95);
        final Color activeColor = Color.lerp(coldColor, hotColor, heatLevel * 0.8 + wave * 0.2)!;

        paint.color = activeColor;
        canvas.drawCircle(Offset(cx, cy), finalSize, paint);

        // Draw faint glowing border for highly active cells
        if (isListening && heatLevel > 0.6) {
          final Paint glowPaint = Paint()
            ..color = hotColor.withValues(alpha: 0.15 * wave)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0.r;
          canvas.drawCircle(Offset(cx, cy), finalSize + 4.0.r, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ThermalGridPainter oldDelegate) {
    return oldDelegate.heatLevel != heatLevel ||
        oldDelegate.isListening != isListening ||
        oldDelegate.time != time;
  }
}
