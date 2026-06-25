import 'dart:math';
import 'package:flutter/material.dart';

/// Performance-optimized auth background with animated neural-network particles.
///
/// ARCHITECTURE NOTE: All particle *state mutation* happens in the
/// [AnimationController] listener ([_tickParticles]). The [CustomPainter.paint]
/// method is kept **pure** (read-only), which satisfies Flutter's rendering
/// contract and prevents undefined behaviour from repeated paint calls in a
/// single frame.
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

  // Seeded for deterministic, stable visual layout.
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat()
          // CRITICAL FIX: Update particle positions in the listener tick, NOT in
          // paint(). paint() must remain a pure rendering function.
          ..addListener(_tickParticles);

    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(_random));
    }
  }

  /// Called every animation frame. Advances all particle positions.
  void _tickParticles() {
    for (final particle in _particles) {
      particle.update(_random);
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
        Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Particle
// ---------------------------------------------------------------------------

class Particle {
  late double x;
  late double y;
  late double speedX;
  late double speedY;
  late double opacity;
  late String text;
  late double fontSize;

  // TextPainter is cached per particle to avoid per-frame allocation.
  // Reset to null in [reset()] when text/fontSize changes.
  TextPainter? _cachedPainter;

  // Track the color for which the painter was built so it's invalidated
  // if the color ever changes (defensive correctness).
  Color? _cachedColor;

  Particle(Random random) {
    reset(random);
  }

  void reset(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    speedX = (random.nextDouble() - 0.5) * 0.001;
    speedY = (random.nextDouble() - 0.5) * 0.001;
    opacity = random.nextDouble() * 0.10 + 0.02; // 0.02 – 0.12

    final isUpper = random.nextBool();
    final charCode = random.nextInt(26) + (isUpper ? 65 : 97);
    text = String.fromCharCode(charCode);
    fontSize = random.nextDouble() * 24 + 12; // 12 – 36

    _cachedPainter = null;
    _cachedColor = null;
  }

  /// Returns a cached [TextPainter], rebuilding only when [baseColor] changes
  /// or after [reset()].
  TextPainter getPainter(Color baseColor) {
    if (_cachedPainter == null || _cachedColor != baseColor) {
      _cachedColor = baseColor;
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
      )..layout();
    }
    return _cachedPainter!;
  }

  void update(Random random) {
    x += speedX;
    y += speedY;

    if (x < -0.1 || x > 1.1 || y < -0.1 || y > 1.1) {
      if (random.nextInt(100) < 5) {
        reset(random);
      } else {
        x = x < -0.1 ? 1.1 : (x > 1.1 ? -0.1 : x);
        y = y < -0.1 ? 1.1 : (y > 1.1 ? -0.1 : y);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// ParticlePainter — pure rendering, no mutation
// ---------------------------------------------------------------------------

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  const ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  static const Color _primaryColor = Color(0xFF2563EB);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // ── Neural network connection lines ─────────────────────────────────
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final positions = [
      for (final p in particles) Offset(p.x * size.width, p.y * size.height),
    ];

    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final distance = (positions[i] - positions[j]).distance;
        if (distance < 100) {
          final alpha = (1.0 - distance / 100) * 0.15;
          linePaint.color = _primaryColor.withValues(alpha: alpha);
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }

    // ── Letter particles ─────────────────────────────────────────────────
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final painter = particle.getPainter(_primaryColor);
      painter.paint(
        canvas,
        Offset(
          positions[i].dx - painter.width / 2,
          positions[i].dy - painter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
