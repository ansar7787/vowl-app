import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

/// Reusable lifecycle and state management mixin for vocabulary game screen states.
mixin VocabularyGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  /// Dispatches the initial [FetchVocabularyQuests] event to the [VocabularyBloc].
  void initVocabularyGame() {
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: gameType, level: level),
    );
  }

  /// Disposes gameplay resources via [disposeGame].
  void disposeVocabularyGame() {
    disposeGame();
  }

  /// Evaluates whether the BLoC listener should trigger state updates on transition.
  bool vocabularyListenWhen(VocabularyState prev, VocabularyState curr) {
    if (curr is VocabularyGameComplete && prev is! VocabularyGameComplete) {
      return true;
    }
    if (curr is VocabularyGameOver && prev is! VocabularyGameOver) return true;
    if (curr is VocabularyLoaded && prev is! VocabularyLoaded) return true;
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  /// Handles state changes emitted by [VocabularyBloc].
  void onVocabularyStateChanged(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is VocabularyGameComplete) {
      handleGameComplete(
        context,
        xpEarned: state.xpEarned,
        coinsEarned: state.coinsEarned,
      );
    }
  }

  /// Submits an incorrect answer attempt, recording mistakes and triggering haptics.
  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<VocabularyBloc>().add(const SubmitAnswer(false));
  }

  /// Submits a correct answer attempt, updating progress and celebrating success.
  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<VocabularyBloc>().add(SubmitAnswer(true));
  }

  /// Advances to the next quest in the active level.
  void dispatchNextQuestion() =>
      context.read<VocabularyBloc>().add(const NextQuestion());

  /// Marks a pedagogical hint as consumed.
  void dispatchHintUsed() =>
      context.read<VocabularyBloc>().add(const VocabularyHintUsed());
}
