import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for vocabulary category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class VocabularyMapBackground extends StatelessWidget {
  const VocabularyMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1917), Color(0xFF44403C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Golden Particles
          ...List.generate(15, (i) {
            return Positioned(
              top: (i * 150).h,
              left: (i * 30).w % 1.sw,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.history_edu_rounded,
                  size: 60.r,
                  color: const Color(0xFFF59E0B),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: (2 + i).seconds, color: Colors.white)
              .moveY(
                begin: 0,
                end: -100.h,
                duration: (5 + i).seconds,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -100.h,
                end: 0,
                duration: (5 + i).seconds,
                curve: Curves.easeInOut,
              ),
            );
          }),
        ],
      ),
    );
  }
}
