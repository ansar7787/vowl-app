import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering connection lines, orbital nodes, and particle bursts for relative clauses.
class RelativeClausesQuantumPainter extends CustomPainter {
  /// Current touch or hook offset point.
  final Offset? hookPoint;

  /// The origin socket offset point for the connection line.
  final Offset startPoint;

  /// The positions of candidate clause nodes.
  final List<Offset> nodePoints;

  /// The text labels for candidate clause nodes.
  final List<String> nodeLabels;

  /// The primary accent color for active paths and nodes.
  final Color primaryColor;

  /// Whether the user has submitted an answer for the current turn.
  final bool isAnswered;

  /// Whether the submitted answer is correct.
  final bool? isCorrect;

  /// The index of the selected target node.
  final int targetNode;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// Whether compact layout constraints should be used.
  final bool isCompact;

  /// Animation progress value for particle bursts (0.0 to 1.0).
  final double particleValue;

  /// Creates a [RelativeClausesQuantumPainter] instance.
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
    this.particleValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRadius = isCompact ? 36.r : 44.r;
    final glowRadius = bodyRadius + (isCompact ? 6.r : 10.r);
    final baseFontSize = isCompact ? 11.5.sp : 13.5.sp;
    final labelMaxWidth = bodyRadius * 1.68;

    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.6)
      ..strokeWidth = isCompact ? 2.r : 2.5.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Draw Option Node Bubbles
    for (int i = 0; i < nodePoints.length; i++) {
      final isCaught = isAnswered && targetNode == i;
      final isWrong = isAnswered && isCorrect == false && targetNode == i;
      final nodeColor = isCaught
          ? (isCorrect == true
                ? AppColors.gameCorrect
                : AppColors.gameIncorrect)
          : (isWrong ? AppColors.gameIncorrect : primaryColor);

      // Outer Glow
      canvas.drawCircle(
        nodePoints[i],
        glowRadius,
        Paint()
          ..color = nodeColor.withValues(alpha: isCaught ? 0.25 : 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isCompact ? 6 : 10),
      );

      // Particle Burst
      if (isCaught && isCorrect == true && particleValue > 0) {
        final maxRadius = bodyRadius * 2.2;
        final currentRadius =
            bodyRadius + (maxRadius - bodyRadius) * particleValue;
        canvas.drawCircle(
          nodePoints[i],
          currentRadius,
          Paint()
            ..color = AppColors.gameCorrect.withValues(
              alpha: 1.0 - particleValue,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5.r,
        );

        for (int p = 0; p < 8; p++) {
          final angle = p * (2 * pi / 8);
          final distance =
              bodyRadius + (maxRadius - bodyRadius) * particleValue;
          final dx = nodePoints[i].dx + distance * cos(angle);
          final dy = nodePoints[i].dy + distance * sin(angle);
          canvas.drawCircle(
            Offset(dx, dy),
            3.5.r * (1.0 - particleValue),
            Paint()
              ..color = AppColors.gameCorrect.withValues(
                alpha: 1.0 - particleValue,
              ),
          );
        }
      }

      // Card Body
      nodePaint.color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.95);
      canvas.drawCircle(nodePoints[i], bodyRadius, nodePaint);

      // Border
      canvas.drawCircle(
        nodePoints[i],
        bodyRadius,
        Paint()
          ..color = nodeColor.withValues(alpha: isCaught ? 0.95 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCaught ? 2.5.r : 1.8.r,
      );

      // Label - Auto-fit text to bubble so it never overflows
      double currentFontSize = baseFontSize;
      TextPainter textPainter;
      final nodeTextColor = isCaught
          ? (isCorrect == true
                ? AppColors.gameCorrect
                : AppColors.gameIncorrect)
          : (isDark ? Colors.white : AppColors.slate900);

      while (true) {
        textPainter = TextPainter(
          text: TextSpan(
            text: nodeLabels[i],
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: currentFontSize,
              fontWeight: FontWeight.w600,
              color: nodeTextColor,
              letterSpacing: 0.2,
              height: 1.25,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: labelMaxWidth);

        if ((textPainter.height <= bodyRadius * 1.5 &&
                textPainter.width <= labelMaxWidth) ||
            currentFontSize <= 8.5.sp) {
          break;
        }
        currentFontSize -= 0.5;
      }

      textPainter.paint(
        canvas,
        nodePoints[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    // Draw Emitter Source
    final emitterRadius = isCompact ? 12.0 : 16.0;

    canvas.drawCircle(
      startPoint,
      emitterRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      startPoint,
      emitterRadius,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      startPoint,
      emitterRadius / 2,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

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
          ? (isCorrect == true
                ? AppColors.gameCorrect
                : AppColors.gameIncorrect)
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
      oldDelegate.isCompact != isCompact ||
      oldDelegate.particleValue != particleValue;
}
