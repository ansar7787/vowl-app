import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Ambient animated pulse circle that sits behind all game content.
///
/// Purely decorative — wrapped in [ExcludeSemantics] so screen readers
/// skip it entirely.
class SpeakingVoicePulseBg extends StatelessWidget {
  final Color color;

  const SpeakingVoicePulseBg({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ExcludeSemantics(
        child: Center(
          child:
              Container(
                    width: 300.r,
                    height: 300.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .blur(begin: const Offset(40, 40), end: const Offset(60, 60)),
        ),
      ),
    );
  }
}
