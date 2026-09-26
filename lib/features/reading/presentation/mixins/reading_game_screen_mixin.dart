import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';

mixin ReadingGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initReadingGame() {
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: gameType, level: level),
    );
  }

  void disposeReadingGame() {
    disposeGame();
  }

  bool readingListenWhen(ReadingState prev, ReadingState curr) {
    if (curr is ReadingGameComplete && prev is! ReadingGameComplete) {
      return true;
    }
    if (curr is ReadingGameOver && prev is! ReadingGameOver) return true;
    if (curr is ReadingLoaded && prev is! ReadingLoaded) return true;
    if (prev is ReadingLoaded &&
        curr is ReadingLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is ReadingLoaded &&
        curr is ReadingLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is ReadingLoaded &&
        curr is ReadingLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onReadingStateChanged(BuildContext context, ReadingState state) {
    if (state is ReadingLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is ReadingGameComplete) {
      handleGameComplete(
        context,
        xpEarned: state.xpEarned,
        coinsEarned: state.coinsEarned,
      );
    }
  }

  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<ReadingBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<ReadingBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<ReadingBloc>().add(const ReadingHintUsed());
}
