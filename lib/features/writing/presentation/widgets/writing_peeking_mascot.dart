import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';

// ---------------------------------------------------------------------------
// WritingPeekingMascot
//
// Extracted from _buildPeekingMascot in WritingBaseLayout.
// Purely decorative — the mascot and its message are excluded from the
// accessibility tree so screen readers aren't distracted by animation noise.
// ---------------------------------------------------------------------------

class WritingPeekingMascot extends StatelessWidget {
  final WritingState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;
  final dynamic theme;

  const WritingPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is WritingGameComplete,
      isGameOver: state is WritingGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'writing',
      mascotId: mascotId,
      isComplete: state is WritingGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    Widget column = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _SpeechBubble(message: message, theme: theme),
        _MascotAvatar(mascotId: mascotId, mascotState: mascotState),
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
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SpeechBubble extends StatelessWidget {
  final String message;
  final dynamic theme;

  const _SpeechBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
          ),
        ),
        child: Text(
          message,
          maxLines: 3,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : (theme.primaryColor ?? const Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }
}

class _MascotAvatar extends StatelessWidget {
  final String mascotId;
  final VowlMascotState mascotState;

  const _MascotAvatar({required this.mascotId, required this.mascotState});

  @override
  Widget build(BuildContext context) {
    return VowlMascot(
      state: mascotState,
      size: 45.r,
      mascotId: mascotId,
    );
  }
}
