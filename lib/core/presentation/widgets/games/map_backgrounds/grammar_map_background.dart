import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/animated_category_background.dart';

/// A premium, highly-performant animated map background for grammar category levels.
///
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class GrammarMapBackground extends StatelessWidget {
  const GrammarMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryMapBackground(
      gradientColors: const [Color(0xFF0F172A), Color(0xFF064E3B)],
      decorationBuilder: (context) => Stack(
        children: List.generate(12, (i) {
          return Positioned(
            top: (i * 180).h,
            left: (i % 2 == 0) ? 0 : null,
            right: (i % 2 != 0) ? 0 : null,
            child:
                Container(
                      width: 300.w,
                      height: 2.h,
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
      ),
    );
  }
}
