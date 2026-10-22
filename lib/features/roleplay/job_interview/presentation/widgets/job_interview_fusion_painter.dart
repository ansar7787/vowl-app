import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfessionalismFusionPainter extends CustomPainter {
  final double animationValue;
  final double professionalismLevel;
  final Color themeColor;

  ProfessionalismFusionPainter({
    required this.animationValue,
    required this.professionalismLevel,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    Color fusionColor = themeColor;
    if (professionalismLevel > 0.6) {
      fusionColor = AppColors.gameCorrect;
    } else if (professionalismLevel < 0.3) {
      fusionColor = AppColors.gameIncorrect;
    }

    // Draw background dim tracker circle
    final Paint trackPaint = Paint()
      ..color = fusionColor.withValues(alpha: 0.12)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 6, trackPaint);

    // Draw professional score arc
    final Paint arcPaint = Paint()
      ..color = fusionColor
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double sweepAngle =
        2 * math.pi * professionalismLevel.clamp(0.01, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // Subtle sleek progress tip indicator
    final double endAngle = (-math.pi / 2) + sweepAngle;
    final double px = center.dx + (radius - 6) * math.cos(endAngle);
    final double py = center.dy + (radius - 6) * math.sin(endAngle);
    final Paint headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(px, py), 2.5.r, headPaint);
  }

  @override
  bool shouldRepaint(covariant ProfessionalismFusionPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.professionalismLevel != professionalismLevel ||
        oldDelegate.themeColor != themeColor;
  }
}
