import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/elite_mastery_bloc.dart';

/// Animated mascot companion peeking into the elite mastery screen.
class ElitePeekingMascot extends StatelessWidget {
  /// Current state of the elite mastery game.
  final EliteMasteryState state;

  /// Lives remaining — controls which motivational message is shown.
  final int lives;

  /// Whether the current question has been answered.
  final bool isAnswered;

  /// Result of the last answer, or `null` if no answer submitted yet.
  final bool? isCorrect;

  /// Creates an [ElitePeekingMascot].
  const ElitePeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isAnswered,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, String>(
      selector: (authState) => authState.user?.vowlMascot ?? 'vowl_prime',
      builder: (context, mascotId) {
        final message = MascotMessageHelper.getMessage(
          context,
          category: 'elite_mastery',
          mascotId: mascotId,
          isComplete: state is EliteMasteryGameComplete,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          lives: lives,
        );

        final mascotState = MascotMessageHelper.getMascotState(
          isComplete: state is EliteMasteryGameComplete,
          isGameOver: state is EliteMasteryGameOver,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          lives: lives,
        );

        return VowlPeekingCompanion(
          message: message,
          mascotState: mascotState,
          mascotId: mascotId,
          category: 'elite_mastery',
        );
      },
    );
  }
}
