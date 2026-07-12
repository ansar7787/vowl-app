import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KidsWorldBackgroundPainter extends StatelessWidget {
  final String gameType;
  const KidsWorldBackgroundPainter({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // A crisp, pedagogical "school" aesthetic background.
    // Light mode: Clean, crisp white with subtle grey notebook dots.
    // Dark mode: Deep slate with subtle dark-blue dots.
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final dotColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Background Dot Grid (Notebook/School Style)
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(color: dotColor, spacing: 30.w),
            ),
          ),

          // Floating Pedagogical Emojis (No blurry glass!)
          ...List.generate(12, (i) => _buildFloatingEmoji(i)),
        ],
      ),
    );
  }

  Widget _buildFloatingEmoji(int i) {
    final random = math.Random(i + 2000);
    final emojis = _getEmojisForGame(gameType);
    final emoji = emojis[random.nextInt(emojis.length)];

    return Positioned(
      top: random.nextDouble() * 1.sh,
      left: random.nextDouble() * 1.sw,
      child: Text(emoji, style: TextStyle(fontSize: (20 + random.nextInt(15)).sp))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: 0,
            end: (random.nextBool() ? 20.h : -20.h),
            duration: (5 + random.nextDouble() * 5).seconds,
            curve: Curves.easeInOutSine,
          )
          // Fade out slowly to make them very subtle and not distract from the game
          .fadeOut(begin: 0.15, duration: 2.seconds),
    );
  }

  List<String> _getEmojisForGame(String type) {
    // School-themed and game-specific crisp emojis
    switch (type) {
      case 'alphabet':
        return ['A', 'b', 'C', '✏️', '📚'];
      case 'numbers':
        return ['1', '2', '3', '➕', '📐'];
      case 'colors':
        return ['🔴', '🔵', '🟡', '🖍️', '🎨'];
      case 'shapes':
        return ['⬛', '🔺', '🔵', '⭐', '📏'];
      case 'animals':
        return ['🐱', '🐶', '🐘', '🐾', '🦋'];
      case 'fruits':
        return ['🍎', '🍌', '🍇', '🍉', '🍓'];
      case 'school':
        return ['🏫', '🎒', '✏️', '📚', '✂️'];
      case 'time':
        return ['⏰', '⌚', '⏳', '📅', '🗓️'];
      case 'day_night':
        return ['☀️', '🌙', '⭐', '☁️', '🌎'];
      default:
        return ['⭐', '💡', '📚', '✏️', '🎯'];
    }
  }
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _DotGridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2.r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}
