import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mascotId =
        context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'vocabulary',
      mascotId: mascotId,
      isComplete: state is VocabularyGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is VocabularyGameComplete,
      isGameOver: state is VocabularyGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

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
          child: VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
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
