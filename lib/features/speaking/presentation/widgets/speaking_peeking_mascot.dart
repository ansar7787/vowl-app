import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

/// Peeking mascot that floats in the top-right corner of the game area.
///
/// Displays a contextual speech bubble + animated mascot character.
/// The speech bubble text is exposed to screen readers via [Semantics].
class SpeakingPeekingMascot extends StatelessWidget {
  /// Current state of the speaking game.
  final SpeakingState state;

  /// Remaining lives count.
  final int lives;

  /// Whether the submitted response was evaluated as correct.
  final bool? isCorrect;

  /// Whether the user has submitted their answer.
  final bool isAnswered;

  /// Companion mascot identifier.
  final String mascotId;

  /// Display name of the active companion mascot.
  final String mascotName;

  /// Creates a [SpeakingPeekingMascot] widget.
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'speaking',
      mascotId: mascotId,
      isComplete: state is SpeakingGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is SpeakingGameComplete,
      isGameOver: state is SpeakingGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

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
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
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
      state: mascotState,
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
      children: [bubble, mascot],
    );

    if (!reduceMotion) {
      column = column.animate().fadeIn().slideX(begin: 0.1, end: 0);
    }

    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: column,
    );
  }
}
