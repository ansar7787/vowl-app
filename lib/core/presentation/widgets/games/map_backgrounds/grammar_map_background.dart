import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for grammar category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class GrammarMapBackground extends StatelessWidget {
  const GrammarMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Logic Circuit Lines
          ...List.generate(12, (i) {
            return Positioned(
              top: (i * 180).h,
              left: (i % 2 == 0) ? 0 : null,
              right: (i % 2 != 0) ? 0 : null,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 300.w,
                  height: 2.h,
                  color: const Color(0xFF10B981),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: (2 + i).seconds, color: Colors.white)
              .moveX(
                begin: (i % 2 == 0) ? -300.w : 300.w,
                end: (i % 2 == 0) ? 1.sw : -1.sw,
                duration: (8 + i).seconds,
              ),
            );
          }),
        ],
      ),
    );
  }
}
