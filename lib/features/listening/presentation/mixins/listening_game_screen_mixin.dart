import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';

/// Shared mixin for all listening game screen states.
mixin ListeningGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Call this from your `initState` after `super.initState()`.
  void initListeningGame() {
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: gameType, level: level),
    );
  }

  /// Call this from your `dispose` before `super.dispose()`.
  void disposeListeningGame() {
    disposeGame();
  }

  // ── Core Bloc Listener Logic ──────────────────────────────────────────

  bool listeningListenWhen(ListeningState prev, ListeningState curr) {
    if (prev is ListeningLoaded && curr is ListeningLoaded) {
      return prev.currentIndex != curr.currentIndex ||
          prev.livesRemaining != curr.livesRemaining ||
          prev.answerStatus != curr.answerStatus ||
          prev.quests != curr.quests;
    }
    return true;
  }

  /// The unified state listener for the `BlocConsumer`.
  void onListeningStateChanged(BuildContext context, ListeningState state) {
    if (state is ListeningLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is ListeningGameComplete) {
      handleGameComplete(
        context,
        xpEarned: state.xpEarned,
        coinsEarned: state.coinsEarned,
      );
    }
  }

  // ── Shared wrong answer / timeout handler ──────────────────────────────

  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    submitSharedCorrectAnswer();
    context.read<ListeningBloc>().add(SubmitAnswer(true));
  }

  // ── Convenience accessors ──────────────────────────────────────────────

  void dispatchNextQuestion() =>
      context.read<ListeningBloc>().add(const NextQuestion());

  void dispatchHintUsed() =>
      context.read<ListeningBloc>().add(const ListeningHintUsed());
}
