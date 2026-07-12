import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SynapticLinkPainter extends CustomPainter {
  final double time;
  final bool isConnected;
  final Color themeColor;

  SynapticLinkPainter({
    required this.time,
    required this.isConnected,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = isConnected
          ? Colors.greenAccent.withValues(alpha: 0.3)
          : themeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.r;

    final Paint glowPaint = Paint()
      ..color = isConnected ? Colors.greenAccent : themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.r
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.r);

    final Path path = Path();
    path.moveTo(size.width / 2, 0);

    // Double Bezier curving flow representing dynamic synaptic transmission
    path.cubicTo(
      size.width / 2 - 30.w,
      size.height * 0.3,
      size.width / 2 + 30.w,
      size.height * 0.7,
      size.width / 2,
      size.height,
    );

    canvas.drawPath(path, linePaint);
    if (isConnected) {
      canvas.drawPath(path, glowPaint);
    }

    // Floating electrical nodes/particles along the bezier path
    final pathMetrics = path.computeMetrics();
    for (var metric in pathMetrics) {
      final double progress = (time * 0.8) % 1.0;
      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent != null) {
        final Paint particlePaint = Paint()
          ..color = isConnected ? Colors.greenAccent : Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(tangent.position, 4.r, particlePaint);
        canvas.drawCircle(
          tangent.position,
          8.r,
          Paint()
            ..color = (isConnected ? Colors.greenAccent : themeColor)
                .withValues(alpha: 0.4)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.r),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SynapticLinkPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.isConnected != isConnected;
  }
}
