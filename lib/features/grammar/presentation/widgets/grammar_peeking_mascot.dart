import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_state.dart';

/// Animated mascot companion peeking into the grammar screen to provide encouragement and reaction cues.
class GrammarPeekingMascot extends StatelessWidget {
  /// Active state of the grammar BLoC.
  final GrammarState state;

  /// Remaining player lives.
  final int lives;

  /// Evaluation outcome of the answer (`null` if unanswered).
  final bool? isCorrect;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Unique identifier for the user's mascot (e.g. `"vowl_prime"`).
  final String mascotId;

  /// Creates a [GrammarPeekingMascot] widget.
  const GrammarPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.mascotId,
  });

  @override
  Widget build(BuildContext context) {
    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is GrammarGameComplete,
      isGameOver: state is GrammarGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'grammar',
      mascotId: mascotId,
      isComplete: state is GrammarGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotState,
      mascotId: mascotId,
      category: 'grammar',
    );
  }
}
