import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium, highly-performant animated map background for the elite mastery category levels.
/// 
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class EliteMasteryMapBackground extends StatelessWidget {
  const EliteMasteryMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF78350F)], // Slate Grey to Imperial Gold
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Floating Premium Badges & Sparks
          ...List.generate(12, (i) {
            final isStar = i % 2 == 0;
            return Positioned(
              top: (i * 180).h,
              left: (i * 45).w % 1.sw,
              child: Icon(
                isStar ? Icons.auto_awesome_rounded : Icons.workspace_premium_rounded,
                size: (isStar ? 40 : 60).r,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: (2 + (i % 3)).seconds, color: Colors.white)
              .moveY(
                begin: 0,
                end: -80.h,
                duration: (6 + i).seconds,
                curve: Curves.easeInOut,
              )
              .then()
              .moveY(
                begin: -80.h,
                end: 0,
                duration: (6 + i).seconds,
                curve: Curves.easeInOut,
              ),
            );
          }),
        ],
      ),
    );
  }
}
