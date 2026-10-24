import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';

/// Mixin providing boilerplate lifecycle and state-dispatch methods
/// for roleplay minigame screens.
mixin RoleplayGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  /// Initializes the roleplay game by requesting quests for [gameType] and [level].
  void initRoleplayGame() {
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: gameType, level: level),
    );
  }

  /// Disposes roleplay game resources.
  void disposeRoleplayGame() {
    disposeGame();
  }

  /// Evaluates whether the BLoC listener should react to state transitions from [prev] to [curr].
  bool roleplayListenWhen(RoleplayState prev, RoleplayState curr) {
    if (curr is RoleplayGameComplete && prev is! RoleplayGameComplete) {
      return true;
    }
    if (curr is RoleplayGameOver && prev is! RoleplayGameOver) return true;
    if (curr is RoleplayLoaded && prev is! RoleplayLoaded) return true;
    if (prev is RoleplayLoaded &&
        curr is RoleplayLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is RoleplayLoaded &&
        curr is RoleplayLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is RoleplayLoaded &&
        curr is RoleplayLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  /// Handles roleplay BLoC state changes, dispatching UI updates and level completions.
  void onRoleplayStateChanged(BuildContext context, RoleplayState state) {
    if (state is RoleplayLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is RoleplayGameComplete) {
      handleGameComplete(
        context,
        xpEarned: state.xpEarned,
        coinsEarned: state.coinsEarned,
      );
    }
  }

  /// Dispatches an incorrect answer submission to the BLoC.
  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<RoleplayBloc>().add(const SubmitAnswer(false));
  }

  /// Dispatches a correct answer submission to the BLoC.
  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<RoleplayBloc>().add(SubmitAnswer(true));
  }

  /// Dispatches an event to advance to the next question.
  void dispatchNextQuestion() =>
      context.read<RoleplayBloc>().add(const NextQuestion());

  /// Dispatches an event recording that a hint was used.
  void dispatchHintUsed() =>
      context.read<RoleplayBloc>().add(const RoleplayHintUsed());
}
