import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';

/// Animated mascot companion peeking into the reading screen.
class ReadingPeekingMascot extends StatelessWidget {
  final int lives;
  final bool? isCorrect;
  final bool isAnswered;
  final bool isGameComplete;
  final bool isGameOver;
  final String mascotId;
  final String mascotName;

  const ReadingPeekingMascot({
    super.key,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
    required this.isGameComplete,
    required this.isGameOver,
    required this.mascotId,
    required this.mascotName,
  });

  @override
  Widget build(BuildContext context) {
    final message = MascotMessageHelper.getMessage(
      context,
      category: 'reading',
      mascotId: mascotId,
      isComplete: isGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotVisualState = MascotMessageHelper.getMascotState(
      isComplete: isGameComplete,
      isGameOver: isGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotVisualState,
      mascotId: mascotId,
      category: 'reading',
    );
  }
}
