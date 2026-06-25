import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/animated_category_background.dart';

/// A premium, highly-performant animated map background for speaking category levels.
///
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class SpeakingMapBackground extends StatelessWidget {
  const SpeakingMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryMapBackground(
      gradientColors: const [Color(0xFF0F172A), Color(0xFF1E1B4B)],
      decorationBuilder: (context) => Stack(
        children: List.generate(6, (i) {
          return Positioned(
            top: (i * 300).h,
            left: (i % 2 == 0) ? -100.w : null,
            right: (i % 2 != 0) ? -100.w : null,
            child:
                Icon(
                      Icons.graphic_eq_rounded,
                      size: 400.r,
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: (3 + i).seconds,
                    ),
          );
        }),
      ),
    );
  }
}
