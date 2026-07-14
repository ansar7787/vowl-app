import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';

/// Animated mascot widget that peeks in from the top-left with a contextual
/// speech bubble.
///
/// [mascotId] is passed explicitly from [ListeningBaseLayout], removing the
/// direct [AuthBloc] read that previously created a cross-feature dependency.
/// The entire widget is wrapped in [ExcludeSemantics] because it is purely
/// decorative — a separate header Semantics node describes lives + level for
/// screen readers.
class ListeningPeekingMascot extends StatelessWidget {
  final ListeningState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;

  /// Resolved mascot identifier — e.g. `'vowl_prime'`.
  /// Callers are responsible for providing a valid, non-empty string.
  final String mascotId;

  const ListeningPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
  });

  @override
  Widget build(BuildContext context) {
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is ListeningGameComplete,
      isGameOver: state is ListeningGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'listening',
      mascotId: mascotId,
      isComplete: state is ListeningGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    // The entire peeking mascot is decorative; the game header Semantics node
    // already communicates lives and level to screen readers.
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SpeechBubble(message: message),
          _MascotSprite(mascotId: mascotId, mascotState: mascotState),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpeechBubble
// ─────────────────────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String message;
  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
            message,
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
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MascotSprite
// ─────────────────────────────────────────────────────────────────────────────

class _MascotSprite extends StatelessWidget {
  final String mascotId;
  final VowlMascotState mascotState;
  const _MascotSprite({required this.mascotId, required this.mascotState});

  @override
  Widget build(BuildContext context) {
    return VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: 8, duration: 1200.ms, curve: Curves.easeInOut)
        .rotate(begin: -0.05, end: 0.05, duration: 2.seconds);
  }
}
