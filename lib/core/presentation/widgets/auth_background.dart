import 'dart:math';
import 'package:flutter/material.dart';

/// A performance-optimized background with dynamic connecting neural network particles for auth.
class AuthBackground extends StatefulWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random(42); // Seeded to maintain clean visual look

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),
        // Animated Particles
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _controller.value,
                  random: _random,
                ),
                child: Container(),
              );
            },
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speedX;
  late double speedY;
  late double opacity;
  late String text;
  late double fontSize;
  TextPainter? _cachedPainter;

  Particle(Random random) {
    reset(random);
  }

  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    speedX = (random.nextDouble() - 0.5) * 0.001; // Even slower
    speedY = (random.nextDouble() - 0.5) * 0.001;
    opacity = random.nextDouble() * 0.1 + 0.02; // Ultra subtle: 0.02 - 0.12

    // Random letter A-Z or a-z
    bool isUpperCase = random.nextBool();
    int charCode = random.nextInt(26) + (isUpperCase ? 65 : 97);
    text = String.fromCharCode(charCode);

    fontSize = random.nextDouble() * 24 + 12; // 12 - 36
    _cachedPainter = null; // Invalidate cached text painter
  }

  /// High-performance caching layer to prevent allocating TextPainters in paint loop
  TextPainter getPainter(Color baseColor) {
    if (_cachedPainter == null) {
      _cachedPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: baseColor.withValues(alpha: opacity),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      _cachedPainter!.layout();
    }
    return _cachedPainter!;
  }

  void update(Random random) {
    x += speedX;
    y += speedY;

    if (x < -0.1 || x > 1.1 || y < -0.1 || y > 1.1) {
      if (random.nextInt(100) < 5) {
        // Small chance to reset to random position
        reset(random);
      } else {
        // Wrap around logic
        x = x < -0.1 ? 1.1 : (x > 1.1 ? -0.1 : x);
        y = y < -0.1 ? 1.1 : (y > 1.1 ? -0.1 : y);
      }
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Random random;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Draw connections (Neural Network)
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < 100) {
          // Connect if close
          final opacity = (1.0 - (distance / 100)) * 0.15; // Max 0.15 opacity
          linePaint.color = const Color(0xFF2563EB).withValues(alpha: opacity);
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    // Draw Letters using high-performance cached TextPainters
    for (var particle in particles) {
      particle.update(random);

      final textPainter = particle.getPainter(const Color(0xFF2563EB));
      textPainter.paint(
        canvas,
        Offset(
          particle.x * size.width - textPainter.width / 2,
          particle.y * size.height - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
