import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_painters.dart';

/// Cosmic circular warp gate displaying the target word to which synonyms must be matched.
class SynonymWarpGate extends StatelessWidget {
  /// The target vocabulary word rendered within the portal core.
  final String word;

  /// Theme accent color for concentric rings, vortex lines, and glowing halos.
  final Color color;

  /// Whether dark theme is enabled.
  final bool isDark;

  /// Optional tap callback executed on gate tap.
  final VoidCallback? onTap;

  /// Whether a candidate shard is actively selected or hovering over the portal.
  final bool hasActiveSelection;

  /// Creates a [SynonymWarpGate] widget.
  const SynonymWarpGate({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
    this.onTap,
    this.hasActiveSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    Widget outerPulse = Container(
      width: 175.r,
      height: 175.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            Colors.transparent,
          ],
          stops: const [0.35, 1.0],
        ),
      ),
    );
    if (!reduceMotion) {
      outerPulse = outerPulse
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.2, 1.2),
            duration: 3.seconds,
            curve: Curves.easeInOut,
          )
          .fadeOut();
    }

    Widget vortex = RepaintBoundary(
      child: CustomPaint(
        painter: VortexPainter(color),
      ),
    );
    if (!reduceMotion) {
      vortex = vortex
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 12.seconds);
    }

    Widget gateCore = Container(
      width: 145.r,
      height: 145.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasActiveSelection
              ? Colors.white
              : color.withValues(alpha: 0.85),
          width: hasActiveSelection ? 3.0 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: hasActiveSelection ? 0.55 : 0.3),
            blurRadius: hasActiveSelection ? 28 : 20,
            spreadRadius: hasActiveSelection ? 4 : 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: vortex),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        word.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasActiveSelection) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'TAP TO MATCH',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!reduceMotion) {
      gateCore = gateCore
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.04, 1.04),
            duration: 2.seconds,
          );
    }

    return RepaintBoundary(
      child: Center(
        child: SizedBox(
          width: 175.r,
          height: 175.r,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                outerPulse,
                gateCore,
                ...List.generate(
                  4,
                  (i) => _buildOrbitalParticle(i, color, reduceMotion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitalParticle(int index, Color color, bool reduceMotion) {
    final duration = (3 + index).seconds;
    Widget particle = RotationTransition(
      turns: AlwaysStoppedAnimation(index * 0.25),
      child: SizedBox(
        width: 140.r,
        height: 140.r,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 5.5.r,
            height: 5.5.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color, blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
        ),
      ),
    );
    if (!reduceMotion) {
      particle = particle
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: duration);
    }
    return particle;
  }
}
