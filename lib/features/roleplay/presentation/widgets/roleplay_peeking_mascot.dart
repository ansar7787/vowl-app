import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';

/// Animated mascot companion peeking into the roleplay screen.
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

    final mascotVisualState = MascotMessageHelper.getMascotState(
      isComplete: state is RoleplayGameComplete,
      isGameOver: state is RoleplayGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotVisualState,
      mascotId: mascotId,
      category: 'roleplay',
    );
  }
}
