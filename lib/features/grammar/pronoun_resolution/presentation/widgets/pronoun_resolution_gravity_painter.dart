import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class PronounResolutionGravityPainter extends CustomPainter {
  final double rotation;
  final Offset centerPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final bool isCorrect;
  final int targetNode;
  final String pronoun;
  final bool isDark;

  PronounResolutionGravityPainter({
    required this.rotation,
    required this.centerPoint,
    required this.nodes,
    required this.options,
    required this.primaryColor,
    required this.isAnswered,
    required this.isCorrect,
    required this.targetNode,
    required this.pronoun,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Orbital Rings
    canvas.drawCircle(
      centerPoint,
      130.r,
      Paint()
        ..color = primaryColor.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.r,
    );

    // Draw Antecedents (Orbiting Satellites)
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final isWrong = isAnswered && !isCorrect && targetNode == i;
      final nodeColor = isHit
          ? Colors.greenAccent
          : (isWrong ? Colors.redAccent : primaryColor);

      // Node Container (Glass Morph)
      final rect = Rect.fromCenter(center: nodes[i], width: 110.w, height: 45.h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12.r)),
        Paint()
          ..color = nodeColor.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(12.r)),
        Paint()
          ..color = nodeColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i].toUpperCase(),
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isHit
                ? Colors.greenAccent
                : (isWrong
                    ? Colors.redAccent
                    : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw Focal Beam
    if (!isAnswered || targetNode != -1) {
      final beamColor = isAnswered
          ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
          : primaryColor;

      final beamPaint = Paint()
        ..color = beamColor.withValues(alpha: 0.3)
        ..strokeWidth = 12.r
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final beamCore = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2.r;

      final beamEnd = isAnswered
          ? nodes[targetNode]
          : Offset(
              centerPoint.dx + cos(rotation) * 160.r,
              centerPoint.dy + sin(rotation) * 160.r,
            );
      canvas.drawLine(centerPoint, beamEnd, beamPaint);
      canvas.drawLine(centerPoint, beamEnd, beamCore);
    }

    // Draw Gravity Core (The Pronoun)
    final coreColor = isAnswered
        ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
        : primaryColor;
    canvas.drawCircle(
      centerPoint,
      40.r,
      Paint()
        ..color = coreColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(centerPoint, 35.r, Paint()..color = coreColor);

    final pronounPainter = TextPainter(
      text: TextSpan(
        text: pronoun.toUpperCase(),
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pronounPainter.paint(
      canvas,
      centerPoint -
          Offset(pronounPainter.width / 2, pronounPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PronounResolutionGravityPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.targetNode != targetNode;
}
