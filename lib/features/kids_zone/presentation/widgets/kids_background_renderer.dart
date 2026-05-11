import 'package:flutter/material.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/backgrounds/kids_world_background_painter.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/backgrounds/generic_kids_background_painter.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KidsBackgroundRenderer extends StatelessWidget {
  final String painterName;
  final String shaderName;
  final Color primaryColor;
  final String gameType;

  const KidsBackgroundRenderer({
    super.key,
    required this.painterName,
    required this.shaderName,
    required this.primaryColor,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        _buildPainter(isDark),
        _buildShaderEffect(),
      ],
    );
  }

  Widget _buildPainter(bool isDark) {
    switch (painterName) {
      case 'KidsWorldBackground':
        return KidsWorldBackgroundPainter(gameType: gameType);
      case 'SunnyMeadow':
        return GenericKidsBackgroundPainter(
          gradientColors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF87CEEB), const Color(0xFFE0F7FA)],
          emojis: const ['☀️', '☁️', '🌸', '🦋'],
        );
      case 'OceanWave':
        return const _OceanWavePainter();
      case 'CandyCloud':
        return GenericKidsBackgroundPainter(
          gradientColors: isDark 
              ? [const Color(0xFF831843), const Color(0xFF500724)]
              : [const Color(0xFFFFC0CB), const Color(0xFFF8BBD0)],
          emojis: const ['🍭', '🍬', '☁️', '🍦'],
        );
      case 'ForestFriend':
        return GenericKidsBackgroundPainter(
          gradientColors: isDark 
              ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
              : [const Color(0xFF388E3C), const Color(0xFFC8E6C9)],
          icon: Icons.eco_rounded,
        );
      case 'StarryNight':
        return GenericKidsBackgroundPainter(
          gradientColors: isDark 
              ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
              : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
          icon: Icons.star_rounded,
          itemCount: 20,
        );
      case 'AlphabetGarden':
        return const KidsWorldBackgroundPainter(gameType: 'alphabet');
      case 'NumbersNebula':
        return const KidsWorldBackgroundPainter(gameType: 'numbers');
      case 'NatureNook':
        return const KidsWorldBackgroundPainter(gameType: 'nature');
      default:
        // Default to a high-quality unified background
        return KidsWorldBackgroundPainter(gameType: gameType);
    }
  }

  Widget _buildShaderEffect() {
    // Shaders can be added here as needed, but for performance 
    // we keep them minimal in the refactor.
    return const SizedBox.shrink();
  }
}

class _OceanWavePainter extends StatelessWidget {
  const _OceanWavePainter();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
        ),
      ),
      child: Stack(
        children: List.generate(10, (i) => _buildBubble(i)),
      ),
    );
  }

  Widget _buildBubble(int i) {
    final random = math.Random(i);
    return Positioned(
      bottom: -50,
      left: random.nextDouble() * 1.sw,
      child: Container(
        width: random.nextDouble() * 40 + 10,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
      ).animate(onPlay: (c) => c.repeat())
       .moveY(begin: 0, end: -1.sh - 100, duration: (5 + random.nextDouble() * 5).seconds, curve: Curves.linear),
    );
  }
}
