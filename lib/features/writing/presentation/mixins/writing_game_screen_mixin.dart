import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';

/// Mixin providing common writing gameplay lifecycle methods and BLoC integration.
mixin WritingGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  /// Initializes the writing game by dispatching [FetchWritingQuests].
  void initWritingGame() {
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: gameType, level: level),
    );
  }

  /// Cleans up game listeners and controllers.
  void disposeWritingGame() {
    disposeGame();
  }

  /// Evaluates whether state transitions in [WritingBloc] warrant a UI notification.
  bool writingListenWhen(WritingState prev, WritingState curr) {
    if (curr is WritingGameComplete && prev is! WritingGameComplete) {
      return true;
    }
    if (curr is WritingGameOver && prev is! WritingGameOver) return true;
    if (curr is WritingLoaded && prev is! WritingLoaded) return true;
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onWritingStateChanged(BuildContext context, WritingState state) {
    if (state is WritingLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is WritingGameComplete) {
      handleGameComplete(
        context,
        xpEarned: state.xpEarned,
        coinsEarned: state.coinsEarned,
      );
    }
  }

  /// Handles an incorrect answer submission, playing haptics/audio and notifying [WritingBloc].
  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<WritingBloc>().add(const SubmitAnswer(false));
  }

  /// Handles a correct answer submission, celebrating and notifying [WritingBloc].
  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  /// Dispatches a request to proceed to the next writing quest.
  void dispatchNextQuestion() =>
      context.read<WritingBloc>().add(const NextQuestion());

  /// Dispatches a hint consumption event to [WritingBloc].
  void dispatchHintUsed() =>
      context.read<WritingBloc>().add(const WritingHintUsed());
}
