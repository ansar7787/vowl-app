import 'package:flutter/material.dart';

class LaserBridgePainter extends CustomPainter {
  final Map<String, String> matches;
  final String? activeKey;
  final Offset? Function(GlobalKey) getCenter;
  final GlobalKey Function(String) getKey;
  final Color color;

  LaserBridgePainter({
    required this.matches,
    required this.activeKey,
    required this.getCenter,
    required this.getKey,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw lines for established matches
    matches.forEach((k, v) {
      final keyCenter = getCenter(getKey(k));
      final valCenter = getCenter(getKey(v));

      if (keyCenter != null && valCenter != null) {
        canvas.drawLine(keyCenter, valCenter, glow);
        canvas.drawLine(keyCenter, valCenter, paint);
        canvas.drawCircle(keyCenter, 5, paint);
        canvas.drawCircle(valCenter, 5, paint);
      }
    });
  }

  @override
  bool shouldRepaint(LaserBridgePainter oldDelegate) => true;
}
