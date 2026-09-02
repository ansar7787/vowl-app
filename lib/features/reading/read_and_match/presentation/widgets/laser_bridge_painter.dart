import 'package:flutter/material.dart';

class LaserBridgePainter extends CustomPainter {
  final Map<String, String> matches;
  final String? activeKey;
  final Offset? Function(GlobalKey) getCenter;
  final GlobalKey Function(String) getKey;
  final Color color;
  final Map<String, Color>? colorMap;

  LaserBridgePainter({
    required this.matches,
    required this.activeKey,
    required this.getCenter,
    required this.getKey,
    required this.color,
    this.colorMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw lines for established matches
    matches.forEach((k, v) {
      final keyCenter = getCenter(getKey(k));
      final valCenter = getCenter(getKey(v));

      final matchColor = colorMap?[k] ?? color;

      final matchPaint = Paint()
        ..color = matchColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final matchGlow = Paint()
        ..color = matchColor.withValues(alpha: 0.35)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      if (keyCenter != null && valCenter != null) {
        canvas.drawLine(keyCenter, valCenter, matchGlow);
        canvas.drawLine(keyCenter, valCenter, matchPaint);
        canvas.drawCircle(keyCenter, 5, matchPaint);
        canvas.drawCircle(valCenter, 5, matchPaint);
      }
    });
  }

  @override
  bool shouldRepaint(LaserBridgePainter oldDelegate) => true;
}
