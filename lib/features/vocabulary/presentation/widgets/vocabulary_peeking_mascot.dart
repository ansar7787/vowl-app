import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

/// Animated mascot companion peeking into the vocabulary screen.
class VocabularyPeekingMascot extends StatelessWidget {
  /// Current state of the vocabulary bloc.
  final VocabularyState state;

  /// Remaining lives count for emotion computation.
  final int lives;

  /// Whether the user answered correctly, or `null` if unanswered.
  final bool? isCorrect;

  /// Whether an answer has been submitted for the active quest.
  final bool isAnswered;

  /// Creates a [VocabularyPeekingMascot] widget.
  const VocabularyPeekingMascot({
    super.key,
    required this.state,
    required this.lives,
    required this.isCorrect,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    final mascotId =
        context.read<AuthBloc>().state.user?.vowlMascot ?? 'vowl_prime';

    final message = MascotMessageHelper.getMessage(
      context,
      category: 'vocabulary',
      mascotId: mascotId,
      isComplete: state is VocabularyGameComplete,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    final mascotState = MascotMessageHelper.getMascotState(
      isComplete: state is VocabularyGameComplete,
      isGameOver: state is VocabularyGameOver,
      isAnswered: isAnswered,
      isCorrect: isCorrect,
      lives: lives,
    );

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotState,
      mascotId: mascotId,
      category: 'vocabulary',
    );
  }
}
