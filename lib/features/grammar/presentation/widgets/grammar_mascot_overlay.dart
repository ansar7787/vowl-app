import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_state.dart';

class GrammarMascotOverlay extends StatelessWidget {
  final GrammarState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;

  /// Unique identifier for the user's mascot (e.g. `"vowl_prime"`).
  final String mascotId;

  const GrammarMascotOverlay({
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
    final mascotState = _resolveMascotState();
    final message = _resolveMessage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpeechBubble(message: message),
        VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: 5,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  VowlMascotState _resolveMascotState() {
    if (state is GrammarGameComplete) return VowlMascotState.happy;
    if (state is GrammarGameOver) return VowlMascotState.worried;
    if (state is GrammarLoaded) {
      if (isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !isAnswered) return VowlMascotState.worried;
      if (isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }

  String _resolveMessage() {
    final displayName = _formatMascotName(mascotId);
    if (state is GrammarGameComplete) return 'Grammar Master! 🏆';
    if (isCorrect == true) return 'Logical Genius! ✨';
    if (isCorrect == false) return 'Analyze the structure! 🔬';
    if (lives < 3 && !isAnswered) return 'Check the logic! 💡';
    return '$displayName is watching! 🦉';
  }

  /// Converts a snake_case [mascotId] (e.g. `"vowl_prime"`) to a display
  /// name (e.g. `"Vowl Prime"`). Guards against empty segments.
  static String _formatMascotName(String mascotId) {
    if (mascotId.isEmpty) return 'Vowl';
    return mascotId
        .split('_')
        .map((s) => s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget
// ---------------------------------------------------------------------------

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
