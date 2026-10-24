import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
  /// Current state from [AccentBloc].
  final AccentState state;

  /// Remaining user lives count.
  final int lives;

  /// Identifier of the selected user mascot.
  final String mascotId;

  /// Whether the last submitted answer was correct (drives speech-bubble copy).
  final bool? isCorrect;

  /// Creates an [AccentPeekingMascot] widget.
  const AccentPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.mascotId,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'accent',
      mascotId: mascotId,
      isComplete: state is AccentGameComplete,
      isAnswered: isCorrect != null,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotVisualState = MascotMessageHelper.getMascotState(
      isComplete: state is AccentGameComplete,
      isGameOver: state is AccentGameOver,
      isAnswered: isCorrect != null,
      isCorrect: isCorrect,
      lives: lives,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: 220.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        maxLines: 3,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706),
        ),
      ),
    );

    if (!reduceMotion) {
      bubble = bubble
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 2.seconds,
          );
    }

    Widget mascot = VowlMascot(
      state: mascotVisualState,
      size: 45.r,
      mascotId: mascotId,
    );
    if (!reduceMotion) {
      mascot = mascot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: 5, duration: 1500.ms, curve: Curves.easeInOut);
    }

    Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [bubble, mascot],
    );

    if (!reduceMotion) {
      column = column.animate().fadeIn().slideX(begin: 0.1, end: 0);
    }

    // RepaintBoundary isolates the continuous bob + shimmer animations from
    // the parent Stack so they never trigger an ancestor repaint.
    return RepaintBoundary(
      child: Semantics(
        liveRegion: true,
        label: message,
        excludeSemantics: true,
        // Decorative widget — TTS nudge handles audio accessibility.
        child: column,
      ),
    );
  }
}
