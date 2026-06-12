import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for reading category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class ReadingMapBackground extends StatelessWidget {
  const ReadingMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1D1D), Color(0xFF063333)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Floating Book Icons
          ...List.generate(8, (i) {
            return Positioned(
              top: (i * 250).h,
              left: (i % 3 == 0) ? 20.w : (i % 3 == 1 ? 150.w : 300.w),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 80.r,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
              )
              .animate(onPlay: (c) => c.repeat())
              .moveY(
                begin: 0,
                end: -40.h,
                duration: (4 + i).seconds,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -40.h,
                end: 0,
                duration: (4 + i).seconds,
                curve: Curves.easeInOut,
              ),
            );
          }),
        ],
      ),
    );
  }
}
