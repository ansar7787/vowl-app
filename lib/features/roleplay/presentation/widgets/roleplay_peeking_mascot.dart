import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';

/// Decorative mascot shown peeking from the top-right corner of the content area.
///
/// The mascot and its speech bubble are purely decorative — they are excluded
/// from the accessibility tree via [ExcludeSemantics].
///
/// [mascotId] is passed in by the screen layer (which reads [AuthBloc]),
/// keeping this widget free of cross-feature coupling.
///
/// Wrapped in [RepaintBoundary] to isolate the continuous float + scale
/// animations from parent layer repaints.
class RoleplayPeekingMascot extends StatelessWidget {
  const RoleplayPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
  });

  final RoleplayState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;

  /// Mascot asset identifier, e.g. `'vowl_prime'`.
  /// Provided by the parent screen — not read internally.
  final String mascotId;

  @override
  Widget build(BuildContext context) {
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'roleplay',
      mascotId: mascotId,
      isComplete: state is RoleplayGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is RoleplayGameComplete,
      isGameOver: state is RoleplayGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return RepaintBoundary(
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SpeechBubble(message: message),
            SizedBox(height: 4.h),
            VowlMascot(state: mascotState, size: 45.r, mascotId: mascotId)
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

// ── Private sub-widget ─────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

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
