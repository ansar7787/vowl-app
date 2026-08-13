import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

/// A custom painter that draws organic Bézier paths connecting quest-map nodes.
///
/// Renders two layers:
///  1. A dim "locked" path spanning all nodes.
///  2. A brighter "active" path that only reaches the [unlockedLevels]th node,
///     accompanied by a glow effect.
class CategoryPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final GameCategory category;
  final bool isDark;
  final int unlockedLevels;
  final int completedLevels;

  /// 0.0 → 1.0: animated active-path draw progress (for screen-entry & unlock)
  final double activePathProgress;

  /// 0.0 → 1.0: glow pulse value for the current-node connection
  final double glowPulse;

  const CategoryPathPainter({
    required this.points,
    required this.color,
    required this.category,
    required this.isDark,
    required this.unlockedLevels,
    required this.completedLevels,
    this.activePathProgress = 1.0,
    this.glowPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final lockedPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      // Use logical pixels (not .r) for stroke widths so they stay consistent
      // across display densities without ScreenUtil's radius scaling.
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final topCenter = Offset(size.width / 2, 0);

    // ── Top connection point with glow ──────────────────────────────────
    canvas.drawCircle(topCenter, 10.0, Paint()..color = color);

    final topGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromCircle(center: topCenter, radius: 25.0));
    canvas.drawCircle(topCenter, 25.0, topGlowPaint);

    // ── Full locked path ─────────────────────────────────────────────────
    final lockedPath = _buildPath(topCenter, points, 0, points.length);
    canvas.drawPath(lockedPath, lockedPaint);

    // ── Active (unlocked) path with animated draw ────────────────────────
    if (points.isNotEmpty) {
      final activeNodeCount = (completedLevels + 1).clamp(0, points.length);
      final activePath = _buildPath(topCenter, points, 0, activeNodeCount);

      // Clip the active path based on activePathProgress
      for (final metric in activePath.computeMetrics()) {
        final clippedPath =
            metric.extractPath(0, metric.length * activePathProgress);

        // Soft glow layer beneath the active path
        canvas.drawPath(
          clippedPath,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..strokeWidth = 16.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
        );

        canvas.drawPath(clippedPath, activePaint);

        // Sparkle tip during animated draw
        if (activePathProgress < 1.0 && activePathProgress > 0.0) {
          final tangent =
              metric.getTangentForOffset(metric.length * activePathProgress);
          if (tangent != null) {
            canvas.drawCircle(
              tangent.position,
              8.0,
              Paint()
                ..color = Colors.white
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
            );
            canvas.drawCircle(
              tangent.position,
              5.0,
              Paint()..color = color,
            );
          }
        }
      }

      // ── Current-node elegant thin breathing ring ──
      if (glowPulse > 0.0 && activeNodeCount > 0) {
        final currentPoint = points[(activeNodeCount - 1)
            .clamp(0, points.length - 1)];
            
        canvas.drawCircle(
          currentPoint,
          52.0 + 8.0 * glowPulse,
          Paint()
            ..color = color.withValues(alpha: 0.5 * glowPulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 // Thin and elegant
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );
      }
    }

    // ── Toll Gate Path (Dashed Gold) ──────────────────────────────────────
    if (points.isNotEmpty &&
        completedLevels == unlockedLevels &&
        completedLevels < points.length) {
      // The segment from completedLevels to completedLevels + 1 is the toll gate segment
      final tollStart = completedLevels == 0
          ? topCenter
          : points[completedLevels - 1];
      final tollEnd = points[completedLevels];

      final tollPath = Path()..moveTo(tollStart.dx, tollStart.dy);
      final mid = (tollEnd.dy - tollStart.dy) / 2;
      tollPath.cubicTo(
        tollStart.dx,
        tollStart.dy + mid,
        tollEnd.dx,
        tollEnd.dy - mid,
        tollEnd.dx,
        tollEnd.dy,
      );

      final tollPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      _drawDashedPath(canvas, tollPath, tollPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 15.0;
    const dashSpace = 10.0;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  /// Builds a Bézier path from [start] through [points[from]..points[to-1]].
  Path _buildPath(Offset start, List<Offset> pts, int from, int to) {
    final path = Path()..moveTo(start.dx, start.dy);
    if (pts.isEmpty || from >= pts.length) return path;
    path.lineTo(pts[from].dx, pts[from].dy);

    for (int i = from; i < to - 1 && i < pts.length - 1; i++) {
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final mid = (p2.dy - p1.dy) / 2;
      path.cubicTo(p1.dx, p1.dy + mid, p2.dx, p2.dy - mid, p2.dx, p2.dy);
    }
    return path;
  }

  /// CRITICAL FIX: Always returned `false`, meaning the painter never updated
  /// when [unlockedLevels], [color], or [isDark] changed after first render.
  @override
  bool shouldRepaint(covariant CategoryPathPainter oldDelegate) {
    return oldDelegate.unlockedLevels != unlockedLevels ||
        oldDelegate.completedLevels != completedLevels ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.points.length != points.length ||
        oldDelegate.category != category ||
        oldDelegate.activePathProgress != activePathProgress ||
        oldDelegate.glowPulse != glowPulse;
  }
}

// ---------------------------------------------------------------------------
// Triangle speech-bubble tail painter
// ---------------------------------------------------------------------------

/// Paints a downward-pointing equilateral triangle for mascot dialogue tails.
class TrianglePainter extends CustomPainter {
  final Color color;

  const TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  /// CRITICAL FIX: Was always `false`, so color changes were invisible.
  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
