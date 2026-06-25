import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// A performance-optimized background golden dust decoration for vocabulary maps.
class GoldenDust extends StatelessWidget {
  final Color color;
  const GoldenDust({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(
      42,
    ); // Seeded to prevent particle snapping on rebuilds
    return RepaintBoundary(
      child: Stack(
        children: List.generate(15, (index) {
          final size = (2 + random.nextInt(4)).r;
          final startX = random.nextDouble() * 1.sw;
          final startY = random.nextDouble() * 1.sh;
          final duration = 3000 + random.nextInt(4000);

          return Positioned(
            left: startX,
            top: startY,
            child:
                Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: Offset.zero,
                      end: Offset(
                        (random.nextDouble() * 100 - 50).w,
                        (random.nextDouble() * 100 - 50).h,
                      ),
                      duration: duration.ms,
                      curve: Curves.easeInOutSine,
                    )
                    .blur(
                      begin: const Offset(0, 0),
                      end: const Offset(2, 2),
                      duration: duration.ms,
                    )
                    .fadeOut(duration: (duration / 2).ms, begin: 0.8),
          );
        }),
      ),
    );
  }
}
