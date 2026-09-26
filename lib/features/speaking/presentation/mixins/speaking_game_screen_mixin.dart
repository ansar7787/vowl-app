import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';

mixin SpeakingGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initSpeakingGame() {
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: gameType, level: level),
    );
  }

  void disposeSpeakingGame() {
    disposeGame();
  }

  bool speakingListenWhen(SpeakingState prev, SpeakingState curr) {
    if (curr is SpeakingGameComplete && prev is! SpeakingGameComplete) {
      return true;
    }
    if (curr is SpeakingGameOver && prev is! SpeakingGameOver) return true;
    if (curr is SpeakingLoaded && prev is! SpeakingLoaded) return true;
    if (prev is SpeakingLoaded &&
        curr is SpeakingLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is SpeakingLoaded &&
        curr is SpeakingLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is SpeakingLoaded &&
        curr is SpeakingLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onSpeakingStateChanged(BuildContext context, SpeakingState state) {
    if (state is SpeakingLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is SpeakingGameComplete) {
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
    context.read<SpeakingBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<SpeakingBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<SpeakingBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<SpeakingBloc>().add(const SpeakingHintUsed());
}
