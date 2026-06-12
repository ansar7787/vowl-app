import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for roleplay category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class RoleplayMapBackground extends StatelessWidget {
  const RoleplayMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1C1917)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Cinema Light Beams
          ...List.generate(6, (i) {
            return Positioned(
              top: -100.h,
              left: (i * 100).w,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  width: 80.w,
                  height: 1.sh,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x0DF59E0B), // 0xFFF59E0B at alpha 0.05
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: (3 + i).seconds, color: Colors.white12),
            );
          }),
        ],
      ),
    );
  }
}
