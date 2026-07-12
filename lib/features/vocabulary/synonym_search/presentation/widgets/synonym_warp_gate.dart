import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';

class SynonymWarpGate extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;

  const SynonymWarpGate({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
                  width: 220.r,
                  height: 220.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.3, 1.3),
                  duration: 3.seconds,
                  curve: Curves.easeInOut,
                )
                .fadeOut(),
            Container(
                  width: 180.r,
                  height: 180.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.8),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 80,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: VortexPainter(color),
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .rotate(duration: 10.seconds),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(25.r),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                word.toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 12,
                                    ),
                                    Shadow(color: color, blurRadius: 25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                ),
            ...List.generate(4, (i) => _buildOrbitalParticle(i, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitalParticle(int index, Color color) {
    final duration = (3 + index).seconds;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(index * 0.25),
      child: SizedBox(
        width: 170.r,
        height: 170.r,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 15, spreadRadius: 2),
              ],
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).rotate(duration: duration);
  }
}
