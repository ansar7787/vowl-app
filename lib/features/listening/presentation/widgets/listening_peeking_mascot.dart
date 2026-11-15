import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';

/// Animated mascot companion peeking into the listening screen.
class ListeningPeekingMascot extends StatelessWidget {
  final ListeningState state;
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;
  final ThemeResult theme;
  final String mascotId;

  const ListeningPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is ListeningGameComplete,
      isGameOver: state is ListeningGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'listening',
      mascotId: mascotId,
      isComplete: state is ListeningGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotState,
      mascotId: mascotId,
      category: 'listening',
    );
  }
}
