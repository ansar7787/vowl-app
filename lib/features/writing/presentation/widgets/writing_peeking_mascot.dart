import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/utils/mascot_message_helper.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';

/// Animated mascot companion peeking into the writing screen.
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

    return VowlPeekingCompanion(
      message: message,
      mascotState: mascotState,
      mascotId: mascotId,
      category: 'writing',
    );
  }
}
