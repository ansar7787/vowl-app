import 'dart:math' as math;
import 'package:flutter/material.dart';

/// High-performance starry night backdrop with smooth drifting and twinkling.
///
/// Star positions are pre-computed with a seeded [math.Random] in [initState].
/// The static [_StarPainter._starShapePath] is allocated once at class
/// construction — zero per-frame path allocation.
class TwinklingStarsBackground extends StatefulWidget {
  final Color starColor;
  final int starCount;
  final double baseOpacity;

  const TwinklingStarsBackground({
    super.key,
    required this.starColor,
    this.starCount = 50,
    this.baseOpacity = 0.4,
  });

  @override
  State<TwinklingStarsBackground> createState() =>
      _TwinklingStarsBackgroundState();
}

class _TwinklingStarsBackgroundState extends State<TwinklingStarsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _generateStars();
  }

  void _generateStars() {
    final rng = math.Random(2000);
    _stars = List.generate(
      widget.starCount,
      (i) => _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2.0 + rng.nextDouble() * 6.0,
        speed: 0.05 + rng.nextDouble() * 0.1,
        drift: (rng.nextDouble() - 0.5) * 0.1,
        twinkleSpeed: 1.0 + rng.nextDouble() * 3.0,
        twinkleOffset: rng.nextDouble() * math.pi * 2,
        type: rng.nextBool() ? _StarType.circle : _StarType.star,
      ),
      growable: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => CustomPaint(
            painter: _StarPainter(
              stars: _stars,
              progress: _controller.value,
              color: widget.starColor.withValues(alpha: widget.baseOpacity),
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

enum _StarType { circle, star }

@immutable
class _Star {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double drift;
  final double twinkleSpeed;
  final double twinkleOffset;
  final _StarType type;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.type,
  });
}

// ---------------------------------------------------------------------------
// Painter — pure rendering, no mutation, static cached path
// ---------------------------------------------------------------------------

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final Color color;

  /// Single static shared path pre-allocated at class load — zero per-frame
  /// path object creation for the 5-point star shape.
  static final Path _starShapePath = () {
    const int points = 5;
    const double angle = (math.pi * 2) / (points * 2);
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? 1.0 : 0.5;
      final x = math.cos(i * angle) * r;
      final y = math.sin(i * angle) * r;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }();

  const _StarPainter({
    required this.stars,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final star in stars) {
      final x = ((star.x + progress * star.drift) % 1.0) * size.width;
      final y = ((star.y + progress * star.speed) % 1.0) * size.height;

      final opacity =
          (math.sin(
                progress * 2 * math.pi * star.twinkleSpeed + star.twinkleOffset,
              ) +
              1.0) /
          2.0;
      paint.color = color.withValues(alpha: color.a * (0.3 + 0.7 * opacity));

      if (star.type == _StarType.circle) {
        canvas.drawCircle(Offset(x, y), star.size / 2, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(star.size / 2);
        canvas.drawPath(_starShapePath, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.progress != progress || old.color != color;
}
