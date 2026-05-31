import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for accent category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class AccentMapBackground extends StatelessWidget {
  const AccentMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Harmonic Waves
          ...List.generate(4, (i) {
            return Positioned(
              top: (200 + i * 200).h,
              left: -100.w,
              right: -100.w,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.waves_rounded,
                  size: 500.r,
                  color: const Color(0xFF818CF8),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(
                begin: -50.w,
                end: 50.w,
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
