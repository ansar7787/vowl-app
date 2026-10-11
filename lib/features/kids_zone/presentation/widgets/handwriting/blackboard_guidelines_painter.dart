import 'package:flutter/material.dart';

/// Paints primary elementary school guidelines and optional faint ghost trace guide.
class BlackboardGuidelinesPainter extends CustomPainter {
  final bool showGuidelines;
  final String? ghostText;

  const BlackboardGuidelinesPainter({
    required this.showGuidelines,
    this.ghostText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (showGuidelines) {
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final dashedPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.24)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // 4 Guidelines: Topline (28%), Midline (48%), Baseline (68%), Descender (85%)
      final toplineY = size.height * 0.28;
      final midlineY = size.height * 0.48;
      final baselineY = size.height * 0.68;
      final descenderY = size.height * 0.85;

      // Topline (solid faint)
      canvas.drawLine(
        Offset(12, toplineY),
        Offset(size.width - 12, toplineY),
        linePaint,
      );

      // Midline (dashed)
      _drawDashedLine(
        canvas,
        Offset(12, midlineY),
        Offset(size.width - 12, midlineY),
        dashedPaint,
      );

      // Baseline (solid grounding line with slightly higher opacity)
      final groundPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(12, baselineY),
        Offset(size.width - 12, baselineY),
        groundPaint,
      );

      // Descender line (solid faint)
      canvas.drawLine(
        Offset(12, descenderY),
        Offset(size.width - 12, descenderY),
        linePaint,
      );
    }

    // Ghost Trace Text / Glyph in faint chalk
    if (ghostText != null && ghostText!.trim().isNotEmpty) {
      final cleanText = ghostText!.trim();
      final textLen = cleanText.length;

      // Scale font size based on text length to comfortably fit inside blackboard
      double fontSize = 96.0;
      if (textLen > 15) {
        fontSize = 24.0;
      } else if (textLen > 8) {
        fontSize = 36.0;
      } else if (textLen > 4) {
        fontSize = 54.0;
      } else if (textLen > 2) {
        fontSize = 72.0;
      }

      final textSpan = TextSpan(
        text: cleanText,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.22),
          letterSpacing: textLen <= 4 ? 4.0 : 1.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 3,
      );

      textPainter.layout(maxWidth: size.width - 32);

      final textX = (size.width - textPainter.width) / 2;
      final textY = (size.height - textPainter.height) / 2;

      textPainter.paint(canvas, Offset(textX, textY));
      textPainter.dispose();
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    double currentX = p1.dx;
    final y = p1.dy;

    while (currentX < p2.dx) {
      final nextX =
          (currentX + dashWidth < p2.dx) ? currentX + dashWidth : p2.dx;
      canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant BlackboardGuidelinesPainter oldDelegate) {
    return oldDelegate.showGuidelines != showGuidelines ||
        oldDelegate.ghostText != ghostText;
  }
}

