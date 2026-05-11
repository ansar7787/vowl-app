import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Premium, multi-emitter confetti for level completion.
/// Features different shapes and realistic physics for a high-end feel.
class GameConfetti extends StatefulWidget {
  final bool shouldPop;
  const GameConfetti({super.key, this.shouldPop = false});

  @override
  State<GameConfetti> createState() => _GameConfettiState();
}

class _GameConfettiState extends State<GameConfetti> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Creates varied shapes for a more dynamic look.
  Path _createVariedPath(Size size) {
    final path = Path();
    final random = Random();
    final shapeType = random.nextInt(3);

    switch (shapeType) {
      case 0: // Rectangle/Paper
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
        break;
      case 1: // Circle
        path.addOval(Rect.fromLTWH(0, 0, size.width * 0.8, size.width * 0.8));
        break;
      case 2: // Triangle/Diamond
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left Emitter
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: 0, // Shoot right
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 40,
            minBlastForce: 20,
            gravity: 0.2,
            createParticlePath: _createVariedPath,
            colors: _confettiColors,
          ),
        ),
        // Right Emitter
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirection: pi, // Shoot left
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            maxBlastForce: 40,
            minBlastForce: 20,
            gravity: 0.2,
            createParticlePath: _createVariedPath,
            colors: _confettiColors,
          ),
        ),
        // Center Burst
        Align(
          alignment: const Alignment(0, -0.8),
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.02,
            numberOfParticles: 30,
            gravity: 0.1,
            maxBlastForce: 80,
            minBlastForce: 40,
            createParticlePath: _createVariedPath,
            colors: _confettiColors,
          ),
        ),
      ],
    );
  }

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
}
