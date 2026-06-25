import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/animated_category_background.dart';

/// A premium, highly-performant animated map background for listening category levels.
///
/// Employs [RepaintBoundary] layer isolation to protect active map level nodes,
/// indicators, and shop headers from redundant visual repaint passes.
class ListeningMapBackground extends StatelessWidget {
  const ListeningMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryMapBackground(
      gradientColors: const [Color(0xFF1E1B4B), Color(0xFF312E81)],
      decorationBuilder: (context) => Stack(
        children: List.generate(5, (i) {
          return Center(
            child:
                Container(
                      width: (200 + i * 200).r,
                      height: (200 + i * 200).r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.5, 1.5),
                      duration: (2 + i).seconds,
                    )
                    .fadeOut(duration: (2 + i).seconds),
          );
        }),
      ),
    );
  }
}
