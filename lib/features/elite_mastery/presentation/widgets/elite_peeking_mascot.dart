import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import '../bloc/elite_mastery_bloc.dart';

/// Floating mascot widget that peeks from the top-left of the game area.
///
/// Extracted from [EliteBaseLayout] to:
///  - Isolate the `AuthBloc` read to a single, small widget.
///  - Allow `RepaintBoundary` to contain the continuous float/scale animations
///    without propagating repaints up to the parent Stack.
///  - Exclude the decorative mascot from the accessibility tree — the
///    TTS service already delivers motivational nudges through audio.
///
/// The mascot reads [AuthBloc] via [BlocSelector] so it only rebuilds when
/// the player's mascot identifier changes (account switch), not on every
/// auth-state update.
class ElitePeekingMascot extends StatelessWidget {
  final EliteMasteryState state;

  /// Lives remaining — controls which motivational message is shown.
  final int lives;

  /// Whether the current question has been answered.
  final bool isAnswered;

  /// Result of the last answer, or `null` if no answer submitted yet.
  final bool? isCorrect;



  const ElitePeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isAnswered,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // BlocSelector: only rebuilds when the mascot ID changes (account switch).
    // Auth-state changes unrelated to mascot selection are filtered out.
    return BlocSelector<AuthBloc, AuthState, String>(
      selector: (authState) => authState.user?.vowlMascot ?? 'vowl_prime',
      builder: (context, mascotId) {
        final mascotState = MascotMessageHelper.getMascotState(
          isComplete: state is EliteMasteryGameComplete,
          isGameOver: state is EliteMasteryGameOver,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          lives: lives,
        );
        final message = MascotMessageHelper.getMessage(
          context,
          category: 'elite_mastery',
          mascotId: mascotId,
          isComplete: state is EliteMasteryGameComplete,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          lives: lives,
        );

        // ExcludeSemantics: the mascot bubble is motivational / decorative.
        // The TTS service already speaks nudges at the right moment; having a
        // screen reader additionally read "Vowl Prime is watching! 🦉" on
        // every state change would be noisy and unhelpful.
        return ExcludeSemantics(
          // RepaintBoundary: the bobbing float and pulse-scale animations run
          // on a continuous loop. Isolating them prevents every animation frame
          // from propagating a repaint up through the full parent Stack tree.
          child: RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpeechBubble(message: message),
                _MascotAvatar(mascotId: mascotId, mascotState: mascotState),
              ],
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
          ),
        );
      },
    );
  }


}

// ── Private sub-widgets ─────────────────────────────────────────────────────

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
              color: const Color(0xFFF59E0B),
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

class _MascotAvatar extends StatelessWidget {
  final String mascotId;
  final VowlMascotState mascotState;

  const _MascotAvatar({required this.mascotId, required this.mascotState});

  @override
  Widget build(BuildContext context) {
    return VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: 5, duration: 1500.ms, curve: Curves.easeInOut);
  }
}
