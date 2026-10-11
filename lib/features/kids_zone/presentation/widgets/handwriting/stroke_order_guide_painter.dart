import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints animated stroke order trajectory with start dots, direction arrows, and gliding pointer tip.
class StrokeOrderGuidePainter extends CustomPainter {
  final String target;
  final double progress; // 0..1

  const StrokeOrderGuidePainter({required this.target, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paths = _getCanonicalPaths(target.trim(), size);
    if (paths.isEmpty) return;

    final strokeCount = paths.length;
    final strokeDuration = 1.0 / strokeCount;

    for (int i = 0; i < strokeCount; i++) {
      final strokeStart = i * strokeDuration;
      final strokeEnd = (i + 1) * strokeDuration;
      final strokePts = paths[i];
      if (strokePts.length < 2) continue;

      // 1. Draw Start indicator (Green dot with pulse)
      final startPt = strokePts.first;
      final startPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      final startRingPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(startPt, 6.0, startPaint);
      canvas.drawCircle(startPt, 8.0, startRingPaint);

      // Number badge for multi-stroke characters
      if (strokeCount > 1) {
        final numSpan = TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        );
        final numPainter = TextPainter(
          text: numSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        numPainter.paint(
          canvas,
          Offset(startPt.dx - 14, startPt.dy - numPainter.height / 2),
        );
        numPainter.dispose();
      }

      // 2. Draw destination end dot (Red dot)
      final endPt = strokePts.last;
      final endPaint = Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPt, 4.5, endPaint);

      // 3. Draw active animation
      if (progress >= strokeEnd) {
        // Fully completed stroke in this cycle
        final completePaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke;

        final path = Path()..moveTo(strokePts.first.dx, strokePts.first.dy);
        for (int p = 1; p < strokePts.length; p++) {
          path.lineTo(strokePts[p].dx, strokePts[p].dy);
        }
        canvas.drawPath(path, completePaint);
      } else if (progress >= strokeStart) {
        // Active in-progress stroke
        final localT = (progress - strokeStart) / strokeDuration;
        final currentPt = _interpolatePath(strokePts, localT);

        // Trailing glowing cyan chalk stroke
        final trailPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke;

        final path = _getPartialPath(strokePts, localT);
        canvas.drawPath(path, trailPaint);

        // Animated pointer tip (Golden chalk cursor with pulsing glow)
        final cursorHalo = Paint()
          ..color = Colors.amber.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawCircle(currentPt, 12.0, cursorHalo);

        final cursorPaint = Paint()
          ..color = Colors.amberAccent
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPt, 6.5, cursorPaint);

        final cursorCore = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPt, 3.0, cursorCore);
      }
    }
  }

  Path _getPartialPath(List<Offset> points, double t) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      final destX = points[0].dx + (points[1].dx - points[0].dx) * t;
      final destY = points[0].dy + (points[1].dy - points[0].dy) * t;
      path.lineTo(destX, destY);
      return path;
    }

    final totalSegments = points.length - 1;
    final targetSegment = (t * totalSegments).clamp(0.0, totalSegments.toDouble());
    final segIndex = targetSegment.floor();
    final segT = targetSegment - segIndex;

    for (int i = 1; i <= segIndex && i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (segIndex < points.length - 1) {
      final p1 = points[segIndex];
      final p2 = points[segIndex + 1];
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * segT,
        p1.dy + (p2.dy - p1.dy) * segT,
      );
    }
    return path;
  }

  Offset _interpolatePath(List<Offset> points, double t) {
    if (points.length == 2) {
      return Offset(
        points[0].dx + (points[1].dx - points[0].dx) * t,
        points[0].dy + (points[1].dy - points[0].dy) * t,
      );
    }
    final totalSegments = points.length - 1;
    final targetSegment = (t * totalSegments).clamp(0.0, totalSegments.toDouble());
    final segIndex = targetSegment.floor();
    final segT = targetSegment - segIndex;

    if (segIndex >= points.length - 1) return points.last;
    final p1 = points[segIndex];
    final p2 = points[segIndex + 1];
    return Offset(
      p1.dx + (p2.dx - p1.dx) * segT,
      p1.dy + (p2.dy - p1.dy) * segT,
    );
  }

  List<List<Offset>> _getCanonicalPaths(String clean, Size size) {
    final w = size.width;
    final h = size.height;
    final topY = h * 0.28;
    final midY = h * 0.48;
    final baseY = h * 0.68;
    final centerX = w * 0.5;

    if (clean == '|') {
      return [
        [Offset(centerX, topY), Offset(centerX, baseY)],
      ];
    }
    if (clean == '| |') {
      return [
        [Offset(w * 0.4, topY), Offset(w * 0.4, baseY)],
        [Offset(w * 0.6, topY), Offset(w * 0.6, baseY)],
      ];
    }
    if (clean == '| | | |') {
      return [
        [Offset(w * 0.25, topY), Offset(w * 0.25, baseY)],
        [Offset(w * 0.42, topY), Offset(w * 0.42, baseY)],
        [Offset(w * 0.58, topY), Offset(w * 0.58, baseY)],
        [Offset(w * 0.75, topY), Offset(w * 0.75, baseY)],
      ];
    }
    if (clean == '-' || clean == '—') {
      return [
        [Offset(w * 0.25, midY), Offset(w * 0.75, midY)],
      ];
    }
    if (clean == '=') {
      return [
        [Offset(w * 0.28, midY - 14), Offset(w * 0.72, midY - 14)],
        [Offset(w * 0.28, midY + 14), Offset(w * 0.72, midY + 14)],
      ];
    }
    if (clean == '- - - -') {
      return [
        [Offset(w * 0.18, midY), Offset(w * 0.32, midY)],
        [Offset(w * 0.38, midY), Offset(w * 0.52, midY)],
        [Offset(w * 0.58, midY), Offset(w * 0.72, midY)],
        [Offset(w * 0.78, midY), Offset(w * 0.92, midY)],
      ];
    }
    if (clean == '/') {
      return [
        [Offset(w * 0.35, baseY), Offset(w * 0.65, topY)],
      ];
    }
    if (clean == '\\') {
      return [
        [Offset(w * 0.35, topY), Offset(w * 0.65, baseY)],
      ];
    }
    if (clean == '/ \\') {
      return [
        [Offset(w * 0.32, baseY), Offset(centerX, topY)],
        [Offset(centerX, topY), Offset(w * 0.68, baseY)],
      ];
    }
    if (clean == '+') {
      return [
        [Offset(centerX, topY), Offset(centerX, baseY)],
        [Offset(w * 0.3, midY), Offset(w * 0.7, midY)],
      ];
    }
    if (clean == 'X') {
      return [
        [Offset(w * 0.34, topY), Offset(w * 0.66, baseY)],
        [Offset(w * 0.66, topY), Offset(w * 0.34, baseY)],
      ];
    }
    if (clean == '□') {
      return [
        [
          Offset(w * 0.32, topY),
          Offset(w * 0.68, topY),
          Offset(w * 0.68, baseY),
          Offset(w * 0.32, baseY),
          Offset(w * 0.32, topY),
        ],
      ];
    }
    if (clean == '△') {
      return [
        [
          Offset(centerX, topY),
          Offset(w * 0.68, baseY),
          Offset(w * 0.32, baseY),
          Offset(centerX, topY),
        ],
      ];
    }
    if (clean == '○') {
      final radius = (baseY - topY) / 2;
      final centerY = (topY + baseY) / 2;
      return [
        List.generate(24, (i) {
          final angle = -math.pi / 2 - (i / 23.0) * 2 * math.pi;
          return Offset(
            centerX + radius * math.cos(angle),
            centerY + radius * math.sin(angle),
          );
        }),
      ];
    }
    if (clean == '∩') {
      final radius = w * 0.18;
      return [
        List.generate(20, (i) {
          final angle = math.pi - (i / 19.0) * math.pi;
          return Offset(
            centerX + radius * math.cos(angle),
            topY + radius * (1 - math.sin(angle)),
          );
        }),
      ];
    }
    if (clean == '∪') {
      final radius = w * 0.18;
      return [
        List.generate(20, (i) {
          final angle = (i / 19.0) * math.pi;
          return Offset(
            centerX - radius * math.cos(angle),
            baseY - radius * (1 - math.sin(angle)),
          );
        }),
      ];
    }
    if (clean == '(') {
      return [
        List.generate(20, (i) {
          final t = i / 19.0;
          final y = topY + t * (baseY - topY);
          final x = centerX + 18.0 - math.sin(t * math.pi) * 28.0;
          return Offset(x, y);
        }),
      ];
    }
    if (clean == ')') {
      return [
        List.generate(20, (i) {
          final t = i / 19.0;
          final y = topY + t * (baseY - topY);
          final x = centerX - 18.0 + math.sin(t * math.pi) * 28.0;
          return Offset(x, y);
        }),
      ];
    }
    if (clean == 'A') {
      return [
        [Offset(centerX, topY), Offset(w * 0.35, baseY)],
        [Offset(centerX, topY), Offset(w * 0.65, baseY)],
        [Offset(w * 0.40, midY), Offset(w * 0.60, midY)],
      ];
    }
    if (clean == 'C') {
      return [
        List.generate(20, (i) {
          final angle = math.pi * 0.25 + (i / 19.0) * math.pi * 1.5;
          final radius = (baseY - topY) / 2;
          final centerY = (topY + baseY) / 2;
          return Offset(
            centerX + radius * math.cos(angle),
            centerY - radius * math.sin(angle),
          );
        }),
      ];
    }

    // Default sweep guide
    return [
      [Offset(w * 0.25, midY), Offset(w * 0.75, midY)],
    ];
  }

  @override
  bool shouldRepaint(covariant StrokeOrderGuidePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.target != target;
}

