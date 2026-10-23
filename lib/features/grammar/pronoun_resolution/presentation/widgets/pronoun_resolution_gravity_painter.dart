import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom painter rendering orbital nodes and gravitational alignment vectors for pronoun resolution.
class PronounResolutionGravityPainter extends CustomPainter {
  /// Repaint notifier driving orbital rotation angles.
  final ValueNotifier<double> rotationNotifier;

  /// The list of antecedent candidate options.
  final List<String> options;

  /// The primary accent color for active paths and rings.
  final Color primaryColor;

  /// Whether the user has submitted an answer for the current turn.
  final bool isAnswered;

  /// Whether the selected answer is correct.
  final bool isCorrect;

  /// The index of the selected target node.
  final int targetNode;

  /// The index of the correct antecedent node.
  final int correctNode;

  /// The pronoun string under examination.
  final String pronoun;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// Whether compact layout constraints should be used.
  final bool isCompact;

  /// Creates a [PronounResolutionGravityPainter] instance.
  PronounResolutionGravityPainter({
    required this.rotationNotifier,
    required this.options,
    required this.primaryColor,
    required this.isAnswered,
    required this.isCorrect,
    required this.targetNode,
    required this.correctNode,
    required this.pronoun,
    required this.isDark,
    this.isCompact = false,
  }) : super(repaint: rotationNotifier);

  /// Calculates the central orbit point given [size] and [isCompact].
  static Offset getCenterPoint(Size size, bool isCompact) {
    return Offset(size.width / 2, size.height / 2 + (isCompact ? 10.h : 20.h));
  }

  /// Calculates the orbital positions of candidate nodes given [size], [count], and [isCompact].
  static List<Offset> getNodePoints(Size size, int count, bool isCompact) {
    final centerPoint = getCenterPoint(size, isCompact);
    final double orbitRadius = isCompact ? 80.r : 120.r;

    return List.generate(count, (i) {
      final angle = (i * (2 * pi / count)) - (pi / 2);
      return Offset(
        centerPoint.dx + cos(angle) * orbitRadius,
        centerPoint.dy + sin(angle) * orbitRadius,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = getCenterPoint(size, isCompact);
    final double orbitRadius = isCompact ? 80.r : 120.r;
    final nodes = getNodePoints(size, options.length, isCompact);

    final double nodeW = isCompact ? 80.w : 112.w;
    final double nodeH = isCompact ? 34.h : 44.h;
    final double nodeRadius = isCompact ? 10.r : 14.r;
    final double labelSize = isCompact ? 11.sp : 13.5.sp;
    final double coreOuter = isCompact ? 26.r : 38.r;
    final double coreInner = isCompact ? 22.r : 32.r;
    final double beamWidth = isCompact ? 8.r : 12.r;
    final double beamExtend = isCompact ? 100.r : 150.r;

    // Draw Orbital Rings
    canvas.drawCircle(
      centerPoint,
      orbitRadius,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.r,
    );

    for (int i = 0; i < nodes.length; i++) {
      final isWrong = isAnswered && !isCorrect && targetNode == i;
      final isActuallyCorrect = isAnswered && correctNode == i;

      final nodeColor = isActuallyCorrect
          ? AppColors.gameCorrect
          : (isWrong ? AppColors.gameIncorrect : primaryColor);

      // Node Container
      final rect = Rect.fromCenter(
        center: nodes[i],
        width: nodeW,
        height: nodeH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(nodeRadius)),
        Paint()
          ..color = isDark
              ? nodeColor.withValues(alpha: 0.12)
              : (isActuallyCorrect || isWrong
                    ? nodeColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.95))
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(nodeRadius)),
        Paint()
          ..color = nodeColor.withValues(alpha: isDark ? 0.35 : 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i],
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: isActuallyCorrect
                ? AppColors.gameCorrect
                : (isWrong
                      ? AppColors.gameIncorrect
                      : (isDark ? Colors.white : AppColors.slate900)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Ensure text never overflows node box and never shows ellipses
      final double availableWidth = nodeW - 14.w;
      double scale = 1.0;
      if (textPainter.width > availableWidth) {
        scale = availableWidth / textPainter.width;
      }

      canvas.save();
      canvas.translate(nodes[i].dx, nodes[i].dy);
      if (scale < 1.0) {
        canvas.scale(scale, scale);
      }
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Draw Focal Beam
    if (!isAnswered || targetNode != -1) {
      final beamColor = isAnswered
          ? (isCorrect ? AppColors.gameCorrect : AppColors.gameIncorrect)
          : primaryColor;

      final beamPaint = Paint()
        ..color = beamColor.withValues(alpha: 0.3)
        ..strokeWidth = beamWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final beamCore = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2.r;

      final beamEnd = isAnswered
          ? nodes[targetNode]
          : Offset(
              centerPoint.dx + cos(rotationNotifier.value) * beamExtend,
              centerPoint.dy + sin(rotationNotifier.value) * beamExtend,
            );
      canvas.drawLine(centerPoint, beamEnd, beamPaint);
      canvas.drawLine(centerPoint, beamEnd, beamCore);
    }

    // Draw Central Core (The Pronoun)
    final coreColor = isAnswered
        ? (isCorrect ? AppColors.gameCorrect : AppColors.gameIncorrect)
        : primaryColor;
    canvas.drawCircle(
      centerPoint,
      coreOuter,
      Paint()
        ..color = coreColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(centerPoint, coreInner, Paint()..color = coreColor);

    final pronounPainter = TextPainter(
      text: TextSpan(
        text: pronoun,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: labelSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Ensure core text never overflows circle
    final double maxCoreWidth = coreInner * 1.6;
    double coreScale = 1.0;
    if (pronounPainter.width > maxCoreWidth) {
      coreScale = maxCoreWidth / pronounPainter.width;
    }

    canvas.save();
    canvas.translate(centerPoint.dx, centerPoint.dy);
    if (coreScale < 1.0) {
      canvas.scale(coreScale, coreScale);
    }
    pronounPainter.paint(
      canvas,
      Offset(-pronounPainter.width / 2, -pronounPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PronounResolutionGravityPainter oldDelegate) =>
      oldDelegate.rotationNotifier != rotationNotifier ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.targetNode != targetNode ||
      oldDelegate.isCompact != isCompact;
}
