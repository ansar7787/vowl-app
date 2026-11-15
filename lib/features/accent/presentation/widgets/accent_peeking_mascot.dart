import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_state.dart';

/// Animated mascot companion peeking into the accent screen.
class AccentPeekingMascot extends StatelessWidget {
  /// Current state from [AccentBloc].
  final AccentState state;

  /// Remaining user lives count.
  final int lives;

  /// Identifier of the selected user mascot.
  final String mascotId;

  /// Whether the last submitted answer was correct.
  final bool? isCorrect;

  /// Creates an [AccentPeekingMascot] widget.
  const AccentPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.mascotId,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'accent',
      mascotId: mascotId,
      isComplete: state is AccentGameComplete,
      isAnswered: isCorrect != null,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotVisualState = MascotMessageHelper.getMascotState(
      isComplete: state is AccentGameComplete,
      isGameOver: state is AccentGameOver,
      isAnswered: isCorrect != null,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotVisualState,
      mascotId: mascotId,
      category: 'accent',
    );
  }
}
