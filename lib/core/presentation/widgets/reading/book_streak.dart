import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A performance-optimized background reading streak decoration for reading maps.
class BookStreak extends StatelessWidget {
  final Color color;
  const BookStreak({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: List.generate(5, (index) {
          final left = (index * 0.2) * 1.sw;
          final speed = 2000 + (index * 500);
          return Positioned(
            left: left,
            top: 0,
            bottom: 0,
            child:
                Container(
                      width: 1.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0),
                            color.withValues(alpha: 0.1),
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
                      curve: Curves.linear,
                    ),
          );
        }),
      ),
    );
  }
}
