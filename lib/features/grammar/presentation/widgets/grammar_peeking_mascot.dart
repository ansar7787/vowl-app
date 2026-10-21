import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_state.dart';

class GrammarPeekingMascot extends StatelessWidget {
  final GrammarState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;

  /// Unique identifier for the user's mascot (e.g. `"vowl_prime"`).
  final String mascotId;

  const GrammarPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
  });

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is GrammarGameComplete,
      isGameOver: state is GrammarGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'grammar',
      mascotId: mascotId,
      isComplete: state is GrammarGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

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
      children: [
        _SpeechBubble(message: message),
        mascot,
      ],
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

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
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
          color: isDark ? const Color(0xFF99F6E4) : const Color(0xFF0D9488),
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

    return bubble;
  }
}
