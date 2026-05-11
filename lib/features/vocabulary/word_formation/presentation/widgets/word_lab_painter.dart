import 'package:flutter/material.dart';

class WordLabPainter extends CustomPainter {
  final Color color;
  final double progress;

  WordLabPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw some techy circles
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), 120, paint..strokeWidth = 0.5);

    // Draw connecting lines (circuits)
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    
    // Branching lines
    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.2, size.height * 0.45);
    path.lineTo(size.width * 0.2, size.height * 0.5);

    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.45);
    path.lineTo(size.width * 0.8, size.height * 0.5);

    canvas.drawPath(path, paint);

    // Draw pulse
    if (progress > 0) {
      final pulsePath = Path();
      pulsePath.moveTo(size.width * 0.5, size.height * 0.3);
      pulsePath.lineTo(size.width * 0.5, size.height * 0.3 + (size.height * 0.1 * progress));
      canvas.drawPath(pulsePath, dashPaint..color = color);
    }
  }

  @override
  bool shouldRepaint(WordLabPainter oldDelegate) => oldDelegate.progress != progress;
}
