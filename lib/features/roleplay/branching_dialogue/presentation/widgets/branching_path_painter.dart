import 'package:flutter/material.dart';

class BranchingPathPainter extends CustomPainter {
  final Offset probeOffset;
  final Offset launchCenter;
  final List<Offset> terminalCenters;
  final int? hoveredIndex;
  final Color themeColor;
  final bool isAnswered;
  final int? selectedIndex;
  final int correctIndex;

  BranchingPathPainter({
    required this.probeOffset,
    required this.launchCenter,
    required this.terminalCenters,
    required this.hoveredIndex,
    required this.themeColor,
    required this.isAnswered,
    required this.selectedIndex,
    required this.correctIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset currentProbePos = launchCenter + probeOffset;

    for (int i = 0; i < terminalCenters.length; i++) {
      final Offset termPos = terminalCenters[i];
      final bool isHovered = hoveredIndex == i;
      final bool isSelected = selectedIndex == i;

      Color lineColor = themeColor.withValues(alpha: 0.15);
      double strokeWidth = 1.5;

      if (isAnswered) {
        if (isSelected) {
          lineColor = (i == correctIndex) ? Colors.greenAccent : Colors.redAccent;
          strokeWidth = 3.0;
        } else if (i == correctIndex) {
          lineColor = Colors.greenAccent.withValues(alpha: 0.4);
          strokeWidth = 2.0;
        } else {
          lineColor = Colors.transparent;
        }
      } else if (isHovered) {
        lineColor = themeColor;
        strokeWidth = 3.0;
      }

      final Paint paint = Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      // Draw beautiful Bezier control curves connecting terminals to launcher
      final Path path = Path();
      path.moveTo(launchCenter.dx, launchCenter.dy);
      
      final double controlY = (launchCenter.dy + termPos.dy) / 2;
      path.cubicTo(
        launchCenter.dx, controlY,
        termPos.dx, controlY,
        termPos.dx, termPos.dy,
      );

      canvas.drawPath(path, paint);

      // Draw secondary glowing dynamic signal pulses on active channels
      if (isHovered && !isAnswered) {
        final Paint glowPaint = Paint()
          ..color = themeColor.withValues(alpha: 0.4)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, glowPaint);
      }
    }

    // Always draw an energy line from launch pad directly to the moving probe
    if (!isAnswered && probeOffset != Offset.zero) {
      final Paint activePaint = Paint()
        ..color = themeColor.withValues(alpha: 0.7)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(launchCenter, currentProbePos, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant BranchingPathPainter oldDelegate) {
    return oldDelegate.probeOffset != probeOffset ||
        oldDelegate.launchCenter != launchCenter ||
        oldDelegate.terminalCenters != terminalCenters ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.themeColor != themeColor ||
        oldDelegate.isAnswered != isAnswered ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
