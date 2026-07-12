import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConditionalsChainPainter extends CustomPainter {
  final List<Offset> points;
  final Offset startPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final bool? isCorrect;
  final int targetNode;
  final bool isDark;

  ConditionalsChainPainter({
    required this.points,
    required this.startPoint,
    required this.nodes,
    required this.options,
    required this.primaryColor,
    required this.isAnswered,
    this.isCorrect,
    required this.targetNode,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Logic Terminals
    for (int i = 0; i < nodes.length; i++) {
      final isHit = isAnswered && targetNode == i;
      final isWrong = isAnswered && isCorrect == false && targetNode == i;
      final blockColor = isHit
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
          : (isWrong ? Colors.redAccent : primaryColor);

      // Terminal Glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: nodes[i], width: 280.w, height: 65.h),
          Radius.circular(20.r),
        ),
        Paint()
          ..color = blockColor.withValues(alpha: 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Terminal Body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: nodes[i], width: 260.w, height: 60.h),
          Radius.circular(16.r),
        ),
        Paint()
          ..color = isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
      );

      // Terminal Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: nodes[i], width: 260.w, height: 60.h),
          Radius.circular(16.r),
        ),
        Paint()
          ..color = blockColor.withValues(alpha: (isHit || isWrong) ? 0.6 : 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i],
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: (isHit || isWrong) ? FontWeight.w800 : FontWeight.w600,
            color: isHit
                ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 240.w);
      textPainter.paint(
        canvas,
        nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw Plasma Fusion Arc
    if (points.isNotEmpty || (isAnswered && targetNode != -1)) {
      final end = isAnswered ? nodes[targetNode] : points.last;
      final beamColor = isAnswered
          ? (isCorrect == true ? Colors.greenAccent : Colors.redAccent)
          : primaryColor;

      final plasmaPaint = Paint()
        ..color = beamColor
        ..strokeWidth = 3.r
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Neon Core
      canvas.drawLine(startPoint, end, plasmaPaint);

      // Outer Glow
      canvas.drawLine(
        startPoint,
        end,
        Paint()
          ..color = beamColor.withValues(alpha: 0.3)
          ..strokeWidth = 8.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Fusion Sparkles
      final dist = (end - startPoint).distance;
      final count = (dist / 20.r).floor().clamp(2, 50);
      for (int j = 0; j < count; j++) {
        final pos = Offset.lerp(startPoint, end, j / count)!;
        canvas.drawCircle(
          pos,
          2.r,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConditionalsChainPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.isCorrect != isCorrect ||
      oldDelegate.targetNode != targetNode;
}
