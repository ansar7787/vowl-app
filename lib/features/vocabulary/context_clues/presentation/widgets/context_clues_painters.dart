import 'package:flutter/material.dart';

class PaperGridPainter extends CustomPainter {
  final bool isDark;

  PaperGridPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.blueGrey).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class ScannerCrosshairPainter extends CustomPainter {
  final Color color;
  ScannerCrosshairPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Corner brackets
    const len = 20.0;
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, 0)
        ..lineTo(len, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, len),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - len)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - len, size.height),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(len, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - len),
      paint,
    );

    // Center dot
    canvas.drawCircle(center, 2, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
