import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for writing category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class WritingMapBackground extends StatelessWidget {
  const WritingMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Ink Streaks (Simple Shapes)
          ...List.generate(10, (i) {
            return Positioned(
              top: (i * 200).h,
              left: (i % 2 == 0) ? -50.w : 250.w,
              child: Container(
                width: 200.w,
                height: 400.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.045), // 0.3 * 0.15
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: -500.h,
                end: 1.sh,
                duration: (10 + i).seconds,
              ),
            );
          }),
        ],
      ),
    );
  }
}
