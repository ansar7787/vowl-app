import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BridgePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  BridgePainter({required this.start, required this.end, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 + 50,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);

    canvas.drawCircle(start, 6.r, Paint()..color = color);
    canvas.drawCircle(end, 6.r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
