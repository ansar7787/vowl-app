import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A performance-optimized background acoustic wave visualizer for listening maps.
class SoundWave extends StatelessWidget {
  final Color color;
  const SoundWave({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            return Container(
                  width: (100 + (index * 80)).w,
                  height: (100 + (index * 80)).w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0),
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.05),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: (1500 + index * 500).ms,
                  curve: Curves.easeOut,
                )
                .fadeOut(
                  duration: (1500 + index * 500).ms,
                  curve: Curves.easeOut,
                );
          }),
        ),
      ),
    );
  }
}
