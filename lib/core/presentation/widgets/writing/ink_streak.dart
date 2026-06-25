import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A performance-optimized background ink streak decoration for writing maps.
class InkStreak extends StatelessWidget {
  final Color color;
  const InkStreak({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: List.generate(4, (index) {
          final start = (0.15 + (index * 0.25)) * 1.sw;
          final speed = 3000 + (index * 800);
          return PositionedDirectional(
            start: start,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15,
              child:
                  Container(
                        width: 12.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0),
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.4),
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .moveY(
                        begin: -1.sh,
                        end: 1.sh,
                        duration: speed.ms,
                        curve: Curves.easeInOutSine,
                      )
                      .shake(
                        hz: 0.5,
                        offset: Offset(10.w, 0),
                        duration: (speed * 2).ms,
                      ),
            ),
          );
        }),
      ),
    );
  }
}
