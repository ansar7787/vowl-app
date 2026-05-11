import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CinemaLight extends StatelessWidget {
  final Color color;
  const CinemaLight({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top light beam
        Positioned(
          top: -100.h,
          left: 0,
          right: 0,
          child: Container(
            height: 400.h,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 1.5,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        // Floating particles
        ...List.generate(15, (index) {
          return Positioned(
            left: (index * 0.07).sw,
            top: (index * 0.05).sh,
            child:
                Container(
                      width: 4.r,
                      height: 4.r,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: 0,
                      end: 100.h,
                      duration: (3000 + index * 200).ms,
                      curve: Curves.linear,
                    )
                    .fadeOut(duration: (3000 + index * 200).ms),
          );
        }),
      ],
    );
  }
}
