import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

/// Floating mascot + speech bubble in the top-left of the body area.
///
/// Reacts to game state: happy on correct / completion, worried on low lives,
/// thinking on wrong answers, neutral otherwise.
class VocabularyPeekingMascot extends StatelessWidget {
  final VocabularyState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;

  const VocabularyPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  VowlMascotState _getMascotState() {
    if (state is VocabularyGameComplete) return VowlMascotState.happy;
    if (state is VocabularyGameOver) return VowlMascotState.worried;
    if (state is VocabularyLoaded) {
      if (isCorrect == true) return VowlMascotState.happy;
      if (lives < 3 && !isAnswered) return VowlMascotState.worried;
      if (isCorrect == false) return VowlMascotState.thinking;
    }
    return VowlMascotState.neutral;
  }

  String _getMessage(String mascotName) {
    if (isCorrect == true) return 'Lexical Master! ✨';
    if (state is VocabularyGameComplete) return 'Vocabulary King! 🏆';
    if (lives < 3 && !isAnswered) return 'Hint for help! 💡';
    if (isCorrect == false) return 'Check the definition! 📖';
    return '$mascotName is learning! 🦉';
  }

  /// Converts a snake_case mascot id (e.g. `vowl_prime`) to a display name
  /// (e.g. `Vowl Prime`).  Static so it can be unit-tested without a widget.
  static String formatMascotName(String mascotId) {
    return mascotId
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mascotId =
        context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = formatMascotName(mascotId);
    final message = _getMessage(mascotName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech bubble — maxWidth clamps on tablets and landscape.
        // FIX: Semantics label added so screen readers announce the mascot's
        // current game message (was previously invisible to assistive tech).
        Semantics(
          label: 'Mascot says: $message',
          child:
              Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    constraints: BoxConstraints(maxWidth: 200.w),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 2.seconds,
                  ),
        ),
        Semantics(
          label: 'Game mascot',
          child: VowlMascot(state: _getMascotState(), size: 45.r)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: 8,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .rotate(begin: -0.05, end: 0.05, duration: 2.seconds),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }
}
