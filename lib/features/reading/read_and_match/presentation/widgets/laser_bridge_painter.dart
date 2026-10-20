import 'package:flutter/material.dart';

class LaserBridgePainter extends CustomPainter {
  final Map<String, String> matches;
  final String? activeKey;
  final Rect? Function(GlobalKey) getRect;
  final GlobalKey Function(String) getKey;
  final Color color;
  final Map<String, Color>? colorMap;
  final double animationValue;

  LaserBridgePainter({
    required this.matches,
    required this.activeKey,
    required this.getRect,
    required this.getKey,
    required this.color,
    this.colorMap,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final entries = matches.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final k = entries[i].key;
      final v = entries[i].value;
      final isLast = i == entries.length - 1;

      final keyRect = getRect(getKey(k));
      final valRect = getRect(getKey(v));

      final matchColor = colorMap?[k] ?? color;

      final matchPaint = Paint()
        ..color = matchColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final matchGlow = Paint()
        ..color = matchColor.withValues(alpha: 0.25)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      if (keyRect != null && valRect != null) {
        final start = Offset(keyRect.right, keyRect.center.dy);
        final endTarget = Offset(valRect.left, valRect.center.dy);

        final end = isLast
            ? (Offset.lerp(start, endTarget, animationValue) ?? endTarget)
            : endTarget;

        canvas.drawLine(start, end, matchGlow);
        canvas.drawLine(start, end, matchPaint);

        // Terminal connection nodes
        canvas.drawCircle(start, 4.0, matchPaint);
        canvas.drawCircle(start, 1.8, Paint()..color = Colors.white);

        canvas.drawCircle(end, 4.0, matchPaint);
        canvas.drawCircle(end, 1.8, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LaserBridgePainter oldDelegate) {
    return oldDelegate.matches != matches ||
        oldDelegate.activeKey != activeKey ||
        oldDelegate.color != color ||
        oldDelegate.colorMap != colorMap ||
        oldDelegate.animationValue != animationValue;
  }
}
