import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TechPatternOverlay extends StatelessWidget {
  final double opacity;
  final Color color;

  const TechPatternOverlay({
    super.key,
    this.opacity = 0.05,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          painter: _TechPatternPainter(color: color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _TechPatternPainter extends CustomPainter {
  final Color color;

  _TechPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.r;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 4.r) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 4.r) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
