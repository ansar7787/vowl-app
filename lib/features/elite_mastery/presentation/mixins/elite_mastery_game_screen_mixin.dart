import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

mixin EliteMasteryGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  void initEliteMasteryGame() {
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: gameType, level: level),
    );
  }

  void disposeEliteMasteryGame() {
    disposeGame();
  }

  bool eliteMasteryListenWhen(EliteMasteryState prev, EliteMasteryState curr) {
    if (curr is EliteMasteryGameComplete && prev is! EliteMasteryGameComplete) {
      return true;
    }
    if (curr is EliteMasteryGameOver && prev is! EliteMasteryGameOver) {
      return true;
    }
    if (curr is EliteMasteryLoaded && prev is! EliteMasteryLoaded) return true;
    if (prev is EliteMasteryLoaded &&
        curr is EliteMasteryLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is EliteMasteryLoaded &&
        curr is EliteMasteryLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is EliteMasteryLoaded &&
        curr is EliteMasteryLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onEliteMasteryStateChanged(
    BuildContext context,
    EliteMasteryState state,
  ) {
    if (state is EliteMasteryLoaded) {
      handleStateUpdate(
        currentIndex: state.currentIndex,
        livesRemaining: state.livesRemaining,
        isAnswered: state.answerStatus.isAnswered,
        isCorrect: state.answerStatus.asBoolOrNull,
      );
    }
    if (state is EliteMasteryGameComplete) {
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
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<EliteMasteryBloc>().add(const NextEliteQuestion());
  void dispatchHintUsed() =>
      context.read<EliteMasteryBloc>().add(const MarkEliteHintUsed());
}
