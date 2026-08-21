import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VowelTrapezoidChart extends StatelessWidget {
  final Map<String, dynamic> vowelChart;
  final Color color;
  final bool isDark;

  const VowelTrapezoidChart({
    super.key,
    required this.vowelChart,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double x = (vowelChart['x'] as num?)?.toDouble() ?? 0.5;
    final double y = (vowelChart['y'] as num?)?.toDouble() ?? 0.5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            "VOWEL POSITION",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: 200.w,
            height: 120.h,
            child: CustomPaint(
              painter: _TrapezoidPainter(
                color: color,
                isDark: isDark,
                x: x,
                y: y,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }
}

class _TrapezoidPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final double x;
  final double y;

  _TrapezoidPainter({
    required this.color,
    required this.isDark,
    required this.x,
    required this.y,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Standard IPA trapezoid coordinates
    // Top-left (Front, Close), Top-right (Back, Close)
    // Bottom-left (Front, Open), Bottom-right (Back, Open)
    final Path path = Path()
      ..moveTo(0, 0) // Front High
      ..lineTo(size.width, 0) // Back High
      ..lineTo(size.width * 0.9, size.height) // Back Low
      ..lineTo(size.width * 0.4, size.height) // Front Low
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Grid lines for reference
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.95, size.height * 0.5),
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );

    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.65, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );

    // Calculate dot position
    // x goes from left border to right border at given y
    final double leftEdgeX = size.width * 0.4 * y;
    final double rightEdgeX = size.width - (size.width * 0.1 * y);
    final double dotX = leftEdgeX + (rightEdgeX - leftEdgeX) * x;
    final double dotY = size.height * y;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint dotGlow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 8.r, dotGlow);
    canvas.drawCircle(Offset(dotX, dotY), 5.r, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrapezoidPainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y || oldDelegate.color != color;
  }
}
