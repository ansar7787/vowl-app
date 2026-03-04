import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Smooth colored-paper confetti for level completion.
/// Uses RepaintBoundary to isolate repaints and tuned particle
/// counts for 60fps on mid-range devices.
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
    _controller = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Creates a small paper-rectangle shape for each confetti piece.
  Path _createPaperPath(Size size) {
    final path = Path();
    // Rectangular paper piece with slight variation
    path.addRect(Rect.fromLTWH(0, 0, size.width * 0.8, size.height * 0.5));
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Align(
        alignment: const Alignment(0, -1.0),
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.06,
          numberOfParticles: 18,
          gravity: 0.15,
          maxBlastForce: 60,
          minBlastForce: 30,
          particleDrag: 0.05,
          createParticlePath: _createPaperPath,
          colors: const [
            Color(0xFFFF6B6B), // Coral red
            Color(0xFFFF8E53), // Warm orange
            Color(0xFFFECA57), // Bright yellow
            Color(0xFF48DBFB), // Sky blue
            Color(0xFF0ABDE3), // Ocean blue
            Color(0xFF5F27CD), // Deep purple
            Color(0xFFFF9FF3), // Soft pink
            Color(0xFF1DD1A1), // Mint green
            Color(0xFFFF6348), // Tomato
            Color(0xFFA29BFE), // Lavender
          ],
        ),
      ),
    );
  }
}
