import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';

mixin RoleplayGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initRoleplayGame() {
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: gameType, level: level),
    );
  }

  void disposeRoleplayGame() {
    disposeGame();
  }

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

  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<RoleplayBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<RoleplayBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<RoleplayBloc>().add(const RoleplayHintUsed());
}
