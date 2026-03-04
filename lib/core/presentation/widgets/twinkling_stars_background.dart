import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TwinklingStarsBackground extends StatelessWidget {
  final Color starColor;
  final int starCount;
  final double baseOpacity;

  const TwinklingStarsBackground({
    super.key,
    required this.starColor,
    this.starCount = 80,
    this.baseOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(starCount, (index) {
          final random = math.Random(index + 2000);
          // Slower speed: 12 to 22 seconds for a more graceful fall
          final duration = (12 + random.nextInt(10)).seconds;
          final size = (3 + random.nextInt(12)).r;
          final startX = random.nextDouble() * 1.sw;
          final startY = random.nextDouble() * 1.sh;
          final drift = (random.nextDouble() - 0.5) * 120.w; // More drift

          return Positioned(
            left: startX,
            top: -50.h,
            child:
                Icon(
                      random.nextBool()
                          ? Icons.auto_awesome
                          : Icons.star_rounded,
                      size: size,
                      color: starColor.withValues(alpha: baseOpacity),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: startY,
                      end: 1.sh + 100.h,
                      duration: duration,
                      curve: Curves.linear,
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveX(
                      begin: 0,
                      end: drift,
                      duration: duration,
                      curve: Curves.easeInOut,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.5, 1.5),
                      duration: (1 + random.nextDouble() * 2).seconds,
                      curve: Curves.easeInOut,
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeOut(
                      duration: (0.8 + random.nextDouble() * 1.2).seconds,
                      curve: Curves.easeInOut,
                    ),
          );
        }),
      ),
    );
  }
}
