import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Custom painter rendering dynamic bezier lines connecting the probe to terminal options.
class BranchingPathPainter extends CustomPainter {
  /// Visual offset of the probe.
  final Offset probeOffset;

  /// Center point of the launcher dock.
  final Offset launchCenter;

  /// Center points of all terminal decision nodes.
  final List<Offset> terminalCenters;

  /// Index of currently hovered terminal node.
  final int? hoveredIndex;

  /// Theme accent color.
  final Color themeColor;

  /// Whether the answer has been submitted.
  final bool isAnswered;

  /// Index of the selected terminal node.
  final int? selectedIndex;

  /// Index of the correct terminal node.
  final int correctIndex;

  /// Creates a [BranchingPathPainter] instance.
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
          lineColor = (i == correctIndex)
              ? AppColors.gameCorrect
              : AppColors.gameIncorrect;
          strokeWidth = 3.0;
        } else if (i == correctIndex) {
          lineColor = AppColors.gameCorrect.withValues(alpha: 0.4);
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
        launchCenter.dx,
        controlY,
        termPos.dx,
        controlY,
        termPos.dx,
        termPos.dy,
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
