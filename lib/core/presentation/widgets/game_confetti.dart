import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Multi-emitter confetti burst for level-completion celebrations.
///
/// Three emitters (left, right, top-centre) fire simultaneously for a
/// premium, physical feel. All emitters share a single controller.
class GameConfetti extends StatefulWidget {
  final bool shouldPop;

  const GameConfetti({super.key, this.shouldPop = false});

  @override
  State<GameConfetti> createState() => _GameConfettiState();
}

class _GameConfettiState extends State<GameConfetti> {
  late ConfettiController _controller;

  // Seeded random keeps shape generation deterministic (avoids visual churn).
  final Random _random = Random(42);

  static const List<Color> _confettiColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));

    _controller.addListener(() {
      if (_controller.state == ConfettiControllerState.stopped && mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _controller.play();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.play();
      });
    });
  }

  @override
  void didUpdateWidget(covariant GameConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Guard: only replay when the flag transitions false → true, and only
    // if the controller is still alive.
    if (widget.shouldPop && !oldWidget.shouldPop && mounted) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Generates varied particle shapes (rectangle, circle, triangle) without
  /// allocating a new [Random] on every call.
  Path _createVariedPath(Size size) {
    final path = Path();
    switch (_random.nextInt(3)) {
      case 0: // Rectangle / paper strip
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
      case 1: // Circle
        path.addOval(Rect.fromLTWH(0, 0, size.width * 0.8, size.width * 0.8));
      default: // Triangle
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Left emitter — inward and down.
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: pi / 4,
              emissionFrequency: 0.1,
              numberOfParticles: 15,
              maxBlastForce: 35,
              minBlastForce: 15,
              gravity: 0.3,
              createParticlePath: _createVariedPath,
              colors: _confettiColors,
            ),
          ),
          // Right emitter — inward and down.
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: 3 * pi / 4,
              emissionFrequency: 0.1,
              numberOfParticles: 15,
              maxBlastForce: 35,
              minBlastForce: 15,
              gravity: 0.3,
              createParticlePath: _createVariedPath,
              colors: _confettiColors,
            ),
          ),
          // Centre burst — explosive radial spread.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.2,
              maxBlastForce: 60,
              minBlastForce: 30,
              createParticlePath: _createVariedPath,
              colors: _confettiColors,
            ),
          ),
        ],
      ),
    );
  }
}
