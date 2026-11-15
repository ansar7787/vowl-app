import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

/// Animated mascot companion peeking into the speaking screen.
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
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'speaking',
      mascotId: mascotId,
      isComplete: state is SpeakingGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotVisualState = MascotMessageHelper.getMascotState(
      isComplete: state is SpeakingGameComplete,
      isGameOver: state is SpeakingGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotVisualState,
      mascotId: mascotId,
      category: 'speaking',
    );
  }
}
