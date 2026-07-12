import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RelativeClausesQuantumPainter extends CustomPainter {
  final Offset? hookPoint;
  final Offset startPoint;
  final List<Offset> nodePoints;
  final List<String> nodeLabels;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int targetNode;
  final bool isDark;
  final bool isCompact;

  RelativeClausesQuantumPainter({
    required this.hookPoint,
    required this.startPoint,
    required this.nodePoints,
    required this.nodeLabels,
    required this.primaryColor,
    required this.isAnswered,
    this.isCorrect,
    required this.targetNode,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowRadius = isCompact ? 38.r : 58.r;
    final bodyRadius = isCompact ? 34.r : 52.r;
    final labelFontSize = isCompact ? 11.sp : 14.sp;
    final labelMaxWidth = isCompact ? 75.w : 100.w;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..strokeWidth = isCompact ? 2.r : 3.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Draw Holographic Node Bubbles
    for (int i = 0; i < nodePoints.length; i++) {
      final isCaught = isAnswered && targetNode == i;
      final isWrong = isAnswered && isCorrect == false && targetNode == i;
      final nodeColor = isCaught
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
          : (isWrong ? Colors.redAccent : primaryColor);

      // Outer Plasma Glow
      canvas.drawCircle(
        nodePoints[i],
        glowRadius,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCompact ? 8 : 12),
      );

      // Glass Body
      nodePaint.color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.02);
      canvas.drawCircle(nodePoints[i], bodyRadius, nodePaint);

      // Border
      canvas.drawCircle(
        nodePoints[i],
        bodyRadius,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      final textPainter = TextPainter(
        text: TextSpan(
          text: nodeLabels[i].toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: labelFontSize,
            fontWeight: FontWeight.w900,
            color: isCaught
                ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
                : (isDark ? Colors.white70 : Colors.black87),
            letterSpacing: isCompact ? 1.0 : 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelMaxWidth);
      textPainter.paint(
        canvas,
        nodePoints[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw Kinetic Data Stream
    if (hookPoint != null || isAnswered) {
      final end = isAnswered && targetNode != -1
          ? nodePoints[targetNode]
          : hookPoint!;
      final path = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..cubicTo(
          startPoint.dx,
          (startPoint.dy + end.dy) / 2,
          end.dx,
          (startPoint.dy + end.dy) / 2,
          end.dx,
          end.dy,
        );

      final beamColor = isAnswered
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
          : primaryColor;

      // Neon Data Glow
      canvas.drawPath(
        path,
        linePaint
          ..color = beamColor.withValues(alpha: 0.2)
          ..strokeWidth = isCompact ? 6.r : 10.r
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCompact ? 5 : 8),
      );
      canvas.drawPath(
        path,
        linePaint
          ..color = beamColor.withValues(alpha: 0.4)
          ..strokeWidth = isCompact ? 3.r : 4.r
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCompact ? 2 : 3),
      );
      canvas.drawPath(
        path,
        linePaint
          ..color = beamColor
          ..strokeWidth = isCompact ? 1.5.r : 2.r
          ..maskFilter = null,
      );

      // Terminals
      canvas.drawCircle(
        startPoint,
        isCompact ? 5.r : 8.r,
        Paint()..color = primaryColor,
      );
      canvas.drawCircle(
        end,
        isCompact ? 7.r : 10.r,
        Paint()..color = beamColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RelativeClausesQuantumPainter oldDelegate) =>
      oldDelegate.hookPoint != hookPoint ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.isCorrect != isCorrect ||
      oldDelegate.targetNode != targetNode ||
      oldDelegate.isCompact != isCompact;
}
