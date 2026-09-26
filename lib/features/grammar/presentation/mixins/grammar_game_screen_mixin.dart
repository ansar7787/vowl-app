import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';

mixin GrammarGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initGrammarGame() {
    context.read<GrammarBloc>().add(
      FetchGrammarQuests(gameType: gameType, level: level),
    );
  }

  void disposeGrammarGame() {
    disposeGame();
  }

  bool grammarListenWhen(GrammarState prev, GrammarState curr) {
    if (curr is GrammarGameComplete && prev is! GrammarGameComplete) {
      return true;
    }
    if (curr is GrammarGameOver && prev is! GrammarGameOver) return true;
    if (curr is GrammarLoaded && prev is! GrammarLoaded) return true;
    if (prev is GrammarLoaded &&
        curr is GrammarLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is GrammarLoaded &&
        curr is GrammarLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is GrammarLoaded &&
        curr is GrammarLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onGrammarStateChanged(BuildContext context, GrammarState state) {
    if (state is GrammarLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is GrammarGameComplete) {
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
    context.read<GrammarBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<GrammarBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<GrammarBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<GrammarBloc>().add(const GrammarHintUsed());
}
