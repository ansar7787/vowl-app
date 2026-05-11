import 'dart:math' as math;
import 'package:flutter/material.dart';

class TwinklingStarsBackground extends StatefulWidget {
  final Color starColor;
  final int starCount;
  final double baseOpacity;

  const TwinklingStarsBackground({
    super.key,
    required this.starColor,
    this.starCount = 50, // Reduced slightly for better mobile density
    this.baseOpacity = 0.4,
  });

  @override
  State<TwinklingStarsBackground> createState() => _TwinklingStarsBackgroundState();
}

class _TwinklingStarsBackgroundState extends State<TwinklingStarsBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _generateStars();
  }

  void _generateStars() {
    final random = math.Random(2000);
    _stars = List.generate(widget.starCount, (index) {
      return _Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2.0 + random.nextDouble() * 6.0,
        speed: 0.05 + random.nextDouble() * 0.1,
        drift: (random.nextDouble() - 0.5) * 0.1,
        twinkleSpeed: 1.0 + random.nextDouble() * 3.0,
        twinkleOffset: random.nextDouble() * math.pi * 2,
        type: random.nextBool() ? _StarType.circle : _StarType.star,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _StarPainter(
              stars: _stars,
              progress: _controller.value,
              color: widget.starColor.withValues(alpha: widget.baseOpacity),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

enum _StarType { circle, star }

class _Star {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double drift;
  final double twinkleSpeed;
  final double twinkleOffset;
  final _StarType type;

  _Star({
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

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double progress;
  final Color color;

  _StarPainter({required this.stars, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (final star in stars) {
      // Calculate current position with wrap-around
      double currentY = (star.y + progress * star.speed) % 1.0;
      double currentX = (star.x + progress * star.drift) % 1.0;

      final x = currentX * size.width;
      final y = currentY * size.height;

      // Calculate twinkle effect
      final opacity = (math.sin(progress * 2 * math.pi * star.twinkleSpeed + star.twinkleOffset) + 1.0) / 2.0;
      paint.color = color.withValues(alpha: color.a * (0.3 + 0.7 * opacity));

      if (star.type == _StarType.circle) {
        canvas.drawCircle(Offset(x, y), star.size / 2, paint);
      } else {
        _drawStar(canvas, Offset(x, y), 5, star.size, star.size / 2, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, int points, double innerRadius, double outerRadius, Paint paint) {
    final path = Path();
    final double angle = (math.pi * 2) / (points * 2);

    for (int i = 0; i < points * 2; i++) {
      final double r = (i % 2 == 0) ? outerRadius : innerRadius;
      final double x = center.dx + math.cos(i * angle) * r;
      final double y = center.dy + math.sin(i * angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => true;
}
