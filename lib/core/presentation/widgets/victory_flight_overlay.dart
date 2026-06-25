import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

// Pre-computed, immutable sparkle data to avoid re-generating random values
// on every build() call (which would produce inconsistent layouts on rebuild).
@immutable
class _SparkleData {
  final double topFactor; // fraction of screen height for top offset
  final String emoji;
  final int fontSize;

  const _SparkleData({
    required this.topFactor,
    required this.emoji,
    required this.fontSize,
  });
}

/// Cinematic full-screen overlay of the mascot flying across the screen on
/// level victory, with speed lines and sparkle trails.
///
/// Sparkle positions are pre-computed in [initState] with a seeded [Random]
/// to guarantee consistent visual output across builds.
class VictoryFlightOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final int level;
  final String? accessoryId;

  const VictoryFlightOverlay({
    super.key,
    required this.onFinished,
    this.level = 1,
    this.accessoryId,
  });

  @override
  State<VictoryFlightOverlay> createState() => _VictoryFlightOverlayState();
}

class _VictoryFlightOverlayState extends State<VictoryFlightOverlay> {
  static const int _sparkleCount = 12;
  late final List<_SparkleData> _sparkles;

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Generate sparkle data once here, not in build().
    // Previously _random.nextInt() was called in build(), meaning every
    // rebuild produced different positions.
    final rng = Random(42);
    _sparkles = List.generate(_sparkleCount, (i) {
      return _SparkleData(
        // Use a factor (0.0–1.0) rather than .h so it's layout-independent.
        topFactor: 0.25 + rng.nextInt(200) / 1000.0,
        emoji: i % 2 == 0 ? '✨' : '⭐',
        fontSize: 10 + rng.nextInt(15),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              // ── Speed lines ────────────────────────────────────────────
              for (int i = 0; i < 8; i++)
                Positioned(
                  left: -100,
                  top: (100 + i * 80).h,
                  child:
                      Container(
                            width: 200.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .moveX(
                            begin: 0,
                            end: 1.5.sw,
                            duration: 800.ms,
                            delay: (i * 100).ms,
                          )
                          .fadeOut(),
                ),

              // ── Mascot flight ───────────────────────────────────────────
              Positioned(
                left: -200,
                top: 300.h,
                child:
                    VowlMascot(
                          state: VowlMascotState.happy,
                          size: 120.r,
                          useFloatingAnimation: false,
                          level: widget.level,
                          accessoryId: widget.accessoryId,
                        )
                        .animate(
                          onComplete: (_) {
                            if (mounted) widget.onFinished();
                          },
                        )
                        .moveX(
                          begin: 0,
                          end: 1.2.sw + 200,
                          duration: 1200.ms,
                          curve: Curves.easeInCubic,
                        )
                        .moveY(
                          begin: 0,
                          end: -150.h,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad,
                        )
                        .then()
                        .moveY(
                          begin: 0,
                          end: 200.h,
                          duration: 600.ms,
                          curve: Curves.easeInQuad,
                        )
                        .rotate(
                          begin: 0.1,
                          end: 0.4,
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        )
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(0.4, 0.4),
                          duration: 600.ms,
                          curve: Curves.easeInBack,
                        ),
              ),

              // ── Sparkle trail (pre-computed positions) ──────────────────
              for (int i = 0; i < _sparkles.length; i++)
                _buildSparkle(_sparkles[i], i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(_SparkleData data, int index) {
    final delay = (index * 100).ms;

    return Positioned(
      left: -50,
      top: data.topFactor * 1.sh,
      child: ExcludeSemantics(
        child: Text(data.emoji, style: TextStyle(fontSize: data.fontSize.sp))
            .animate()
            .moveX(
              begin: 0,
              end: 1.2.sw + 50,
              duration: 1000.ms,
              curve: Curves.easeInOutBack,
              delay: delay,
            )
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1.2, 1.2),
              duration: 200.ms,
              delay: delay,
            )
            .then()
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(0, 0),
              duration: 400.ms,
              delay: 500.ms,
            )
            .fadeOut(delay: 750.ms),
      ),
    );
  }
}
