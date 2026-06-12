import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

/// Peeking mascot that floats in the top-right corner of the game area.
///
/// Displays a contextual speech bubble + animated mascot character.
/// The speech bubble text is exposed to screen readers via [Semantics].
class SpeakingPeekingMascot extends StatelessWidget {
  final SpeakingState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;
  final String mascotId;
  final String mascotName;

  const SpeakingPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
    required this.mascotName,
  });

  @override
  Widget build(BuildContext context) {
    final message = _message();
    final mascotState = _mascotState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
              label: 'Mascot says: $message',
              child: Container(
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
                child: ExcludeSemantics(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2.seconds,
            ),
        Semantics(
              label: '$mascotName mascot',
              child: VowlMascot(
                state: mascotState,
                size: 45.r,
                mascotId: mascotId,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: 5,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _message() {
    if (isCorrect == true) return 'Crystal Clear! ✨';
    if (lives < 3 && !isAnswered) return 'Find your voice! 💡';
    if (isCorrect == false) return 'Try one more time! 🎤';
    if (state is SpeakingGameComplete) return 'Oratory Master! 🏆';
    return '$mascotName is watching! 🦉';
  }

  VowlMascotState _mascotState() {
    if (state is SpeakingGameComplete) return VowlMascotState.happy;
    if (state is SpeakingGameOver) return VowlMascotState.worried;
    if (state is SpeakingLoaded) {
      if (isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !isAnswered) return VowlMascotState.worried;
      if (isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }
}
