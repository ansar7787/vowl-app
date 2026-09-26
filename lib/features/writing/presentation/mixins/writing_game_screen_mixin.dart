import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';

mixin WritingGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initWritingGame() {
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: gameType, level: level),
    );
  }

  void disposeWritingGame() {
    disposeGame();
  }

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

  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<WritingBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<WritingBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<WritingBloc>().add(const WritingHintUsed());
}
