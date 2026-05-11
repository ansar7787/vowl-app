import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GenericKidsBackgroundPainter extends StatelessWidget {
  final List<Color> gradientColors;
  final List<String> emojis;
  final IconData? icon;
  final int itemCount;

  const GenericKidsBackgroundPainter({
    super.key,
    required this.gradientColors,
    this.emojis = const [],
    this.icon,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: List.generate(itemCount, (i) => _buildFloatingItem(i)),
      ),
    );
  }

  Widget _buildFloatingItem(int i) {
    final random = math.Random(i);
    return Positioned(
      top: random.nextDouble() * 1.sh,
      left: random.nextDouble() * 1.sw,
      child: _buildContent(random)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: (random.nextBool() ? 30.h : -30.h), duration: (4 + random.nextDouble() * 4).seconds)
          .fadeOut(begin: 0.3, duration: 2.seconds),
    );
  }

  Widget _buildContent(math.Random random) {
    if (emojis.isNotEmpty) {
      return Text(
        emojis[random.nextInt(emojis.length)],
        style: TextStyle(fontSize: (16 + random.nextInt(14)).sp),
      );
    }
    if (icon != null) {
      return Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.2),
        size: (20 + random.nextInt(20)).sp,
      );
    }
    return Container(
      width: 4.r,
      height: 4.r,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }
}
