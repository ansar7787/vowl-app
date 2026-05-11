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
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)] // Deep Navy to Royal Blue
              : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)], // Sky Blue to Mint Green
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(3, (i) => _buildMeshBlob(context, i)),
          ...List.generate(15, (i) => _buildFloatingEmoji(i)),
          ...List.generate(10, (i) => _buildSparkle(i)),
        ],
      ),
    );
  }

  Widget _buildMeshBlob(BuildContext context, int i) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final random = math.Random(i + 1000);
    final colors = isDark 
      ? [
          Colors.blue[700]!.withValues(alpha: 0.15),
          Colors.purple[700]!.withValues(alpha: 0.15),
          Colors.indigo[700]!.withValues(alpha: 0.15),
        ]
      : [
          Colors.blue[100]!.withValues(alpha: 0.3),
          Colors.green[100]!.withValues(alpha: 0.3),
          Colors.purple[100]!.withValues(alpha: 0.3),
        ];
    
    return Positioned(
      top: random.nextDouble() * 1.sh,
      left: random.nextDouble() * 1.sw,
      child: Container(
        width: 300.r,
        height: 300.r,
        decoration: BoxDecoration(
          color: colors[i % colors.length],
          shape: BoxShape.circle,
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .blur(begin: const Offset(50, 50), end: const Offset(80, 80))
       .move(
         begin: Offset.zero, 
         end: Offset(random.nextDouble() * 50 - 25, random.nextDouble() * 50 - 25), 
         duration: (20 + random.nextDouble() * 20).seconds,
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
      child: Text(
        emoji,
        style: TextStyle(fontSize: (14 + random.nextInt(12)).sp),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .moveY(begin: 0, end: (random.nextBool() ? 30.h : -30.h), duration: (5 + random.nextDouble() * 5).seconds)
       .fadeOut(begin: 0.3, duration: 2.seconds),
    );
  }

  Widget _buildSparkle(int i) {
    final random = math.Random(i + 3000);
    return Positioned(
      top: random.nextDouble() * 1.sh,
      left: random.nextDouble() * 1.sw,
      child: Container(
        width: 4.r,
        height: 4.r,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: (1 + random.nextDouble() * 2).seconds)
       .fadeOut(duration: 1.seconds),
    );
  }

  List<String> _getEmojisForGame(String type) {
    switch (type) {
      case 'alphabet': return ['🔤', '🅰️', '🅱️', '🔠', '✏️'];
      case 'numbers': return ['🔢', '1️⃣', '2️⃣', '3️⃣', '➕'];
      case 'colors': return ['🎨', '🌈', '🖍️', '🖌️', '✨'];
      case 'shapes': return ['📐', '🔷', '🔶', '🟢', '🟥'];
      case 'animals': return ['🐘', '🦁', '🦓', '🦒', '🦒'];
      case 'fruits': return ['🍎', '🍓', '🍇', '🍍', '🍒'];
      default: return ['🎈', '🧸', '🌟', '🧩', '🎨'];
    }
  }
}
