import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';

mixin AccentGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initAccentGame() {
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: gameType, level: level),
    );
  }

  void disposeAccentGame() {
    disposeGame();
  }

  bool accentListenWhen(AccentState prev, AccentState curr) {
    if (curr is AccentGameComplete && prev is! AccentGameComplete) return true;
    if (curr is AccentGameOver && prev is! AccentGameOver) return true;
    if (curr is AccentLoaded && prev is! AccentLoaded) return true;
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onAccentStateChanged(BuildContext context, AccentState state) {
    if (state is AccentLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is AccentGameComplete) {
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
    context.read<AccentBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<AccentBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<AccentBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<AccentBloc>().add(const AccentHintUsed());
}
