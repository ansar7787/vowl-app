import 'package:flutter/material.dart';

/// Represents an individual floating chalk dust particle.
class ChalkParticle {
  final double x; // relative X 0..1
  final double y; // relative Y 0..1
  final double vx; // drift velocity x
  final double vy; // drift velocity y
  final double radius;
  final double alpha;

  const ChalkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.alpha,
  });
}

/// Paints playful chalk dust particle puff effect drifting outward when clearing.
class ChalkDustPainter extends CustomPainter {
  final List<ChalkParticle> particles;
  final double progress;

  const ChalkDustPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress >= 1.0) return;

    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentX = (p.x * size.width) + (p.vx * progress);
      final currentY = (p.y * size.height) + (p.vy * progress);
      final currentRadius = p.radius * (1.0 + progress * 0.9);
      final currentAlpha = (p.alpha * fadeOut).clamp(0.0, 1.0);

      // Soft chalk mist halo
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: currentAlpha * 0.45)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawCircle(Offset(currentX, currentY), currentRadius, haloPaint);

      // Core chalk grain
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: currentAlpha * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(currentX, currentY),
        currentRadius * 0.4,
        corePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChalkDustPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

