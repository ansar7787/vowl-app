import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_state.dart';

/// Animated mascot that peeks in from the top-right corner of the game screen.
///
/// Wrapped in [RepaintBoundary] so its continuous `repeat` animation does not
/// invalidate the parent layer on every frame — a meaningful GPU saving on
/// mid-range devices.
///
/// Marked [ExcludeSemantics] because the mascot is entirely decorative.
/// Its speech-bubble message is accessible via the TTS nudge system.
class AccentPeekingMascot extends StatelessWidget {
  final AccentState state;
  final int lives;
  final String mascotId;

  /// Whether the last submitted answer was correct (drives speech-bubble copy).
  final bool? isCorrect;

  const AccentPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.mascotId,
    required this.isCorrect,
  });

  // ── Mascot visual state ──────────────────────────────────────────────────

  VowlMascotState get _mascotVisualState {
    if (state is AccentGameComplete) return VowlMascotState.happy;
    if (state is AccentGameOver) return VowlMascotState.worried;
    if (isCorrect == true) return VowlMascotState.happy;
    if (isCorrect == false) return VowlMascotState.thinking;
    return VowlMascotState.neutral;
  }

  // ── Speech bubble message ────────────────────────────────────────────────

  String _message(String mascotName) {
    if (isCorrect == true) return 'Perfect Accent! ✨';
    if (state is AccentGameComplete) return 'Pronunciation Pro! 🏆';
    if (isCorrect == false) return 'Try once more! 🎤';
    if (lives < 3 && isCorrect == null) return 'You can do it! 💡';
    return '$mascotName is watching! 🦉';
  }

  // ── Mascot display name ──────────────────────────────────────────────────
  //
  // Guards against empty segments produced by consecutive underscores
  // (e.g. 'vowl__prime' or a trailing '_') that previously caused RangeError.

  String _mascotDisplayName() => mascotId
      .split('_')
      .where((segment) => segment.isNotEmpty)
      .map((segment) => segment[0].toUpperCase() + segment.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final mascotName = _mascotDisplayName();

    // RepaintBoundary isolates the continuous bob + shimmer animations from
    // the parent Stack so they never trigger an ancestor repaint.
    return RepaintBoundary(
      child: ExcludeSemantics(
        // Decorative widget — TTS nudge handles audio accessibility.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speech bubble
            Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    _message(mascotName),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                ),

            // Mascot avatar — bobs up and down continuously
            VowlMascot(
                  state: _mascotVisualState,
                  size: 45.r,
                  mascotId: mascotId,
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: 5,
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
          ],
        ).animate().fadeIn().slideX(begin: 0.1, end: 0),
      ),
    );
  }
}
