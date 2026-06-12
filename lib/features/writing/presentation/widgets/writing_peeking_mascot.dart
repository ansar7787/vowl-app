import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
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
    final authState = context.read<AuthBloc>().state;
    final mascotId = authState.user?.vowlMascot ?? 'vowl_prime';
    final mascotName = _formatMascotName(mascotId);
    final mascotState = _resolveMascotState();
    final message = _resolveMessage(mascotName);

    // ACCESSIBILITY: The mascot is a decorative animated element.
    // Excluding it prevents screen readers from announcing animation updates.
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SpeechBubble(message: message, theme: theme),
          // FIX: Removed SizedBox(height: 0.h) — was dead code.
          _MascotAvatar(mascotId: mascotId, mascotState: mascotState),
        ],
      ).animate().fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// FIX: Guards against empty segments (e.g. '_vowl' → ['', 'vowl'])
  /// that previously caused a RangeError on e[0].
  String _formatMascotName(String mascotId) {
    return mascotId
        .split('_')
        .where((e) => e.isNotEmpty)
        .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  String _resolveMessage(String mascotName) {
    return switch (true) {
      _ when isCorrect == true => 'Literary Genius! ✨',
      _ when state is WritingGameComplete => 'Author Extraordinaire! 🏆',
      _ when isCorrect == false => 'Refine the prose! 📜',
      _ when lives < 3 && !isAnswered => 'Find your voice! 💡',
      _ => '$mascotName is waiting! 🦉',
    };
  }

  VowlMascotState _resolveMascotState() {
    if (state is WritingGameComplete) return VowlMascotState.happy;
    if (state is WritingGameOver) return VowlMascotState.worried;
    if (state is WritingLoaded) {
      if (isCorrect == true) return VowlMascotState.happy;
      if (isCorrect == false) return VowlMascotState.thinking;
      if (lives < 3 && !isAnswered) return VowlMascotState.worried;
    }
    return VowlMascotState.neutral;
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
          // ACCESSIBILITY: clamp text scaling so the bubble doesn't overflow at
          // extreme accessibility font sizes (the mascot is decorative context).
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.3),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                // FIX: was Colors.blueAccent — now theme-aware.
                color: theme.primaryColor,
              ),
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
