import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PrepositionPathPainter extends CustomPainter {
  final List<Offset> points;
  final Offset startPoint;
  final List<Offset> nodes;
  final List<String> options;
  final Color primaryColor;
  final bool isAnswered;
  final bool isCorrect;
  final int targetNode;
  final bool isDark;

  PrepositionPathPainter({
    required this.points,
    required this.startPoint,
    required this.nodes,
    required this.options,
    required this.primaryColor,
    required this.isAnswered,
    required this.isCorrect,
    required this.targetNode,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Nodes (Holographic Power Cells)
    for (int i = 0; i < nodes.length; i++) {
      final isTarget = isAnswered && targetNode == i;
      final nodeColor = isTarget ? Colors.greenAccent : primaryColor;

      // Node Aura
      canvas.drawCircle(
        nodes[i],
        45.r,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Node Ring
      canvas.drawCircle(
        nodes[i],
        40.r,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i % options.length],
          style: GoogleFonts.outfit(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: isTarget
                ? Colors.greenAccent
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        nodes[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw Socket
    canvas.drawCircle(
      startPoint,
      18.r,
      Paint()
        ..color = primaryColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(startPoint, 8.r, Paint()..color = Colors.white);

    // Draw Energy Path (Cinematic Laser)
    if (points.isNotEmpty || isAnswered) {
      final path = Path()..moveTo(startPoint.dx, startPoint.dy);
      if (isAnswered && targetNode != -1) {
        path.lineTo(nodes[targetNode].dx, nodes[targetNode].dy);
      } else {
        for (var p in points) {
          path.lineTo(p.dx, p.dy);
        }
      }

      final pathColor = isAnswered
          ? (isCorrect ? Colors.greenAccent : Colors.redAccent)
          : primaryColor;

      // Outer Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = pathColor.withValues(alpha: 0.4)
          ..strokeWidth = 10.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Inner Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = pathColor
          ..strokeWidth = 4.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Core Beam
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5.r
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PrepositionPathPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.isAnswered != isAnswered ||
      oldDelegate.targetNode != targetNode;
}
