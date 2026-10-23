import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

/// Mixin providing shared lifecycle, bloc event routing, and state listeners for elite screens.
mixin EliteMasteryGameScreenMixin<T extends StatefulWidget>
    on State<T>, GameScreenMixin<T> {
  /// Initializes the elite challenge session by requesting quest data.
  void initEliteMasteryGame() {
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: gameType, level: level),
    );
  }

  /// Cleans up game timers, controllers, and resources upon widget disposal.
  void disposeEliteMasteryGame() {
    disposeGame();
  }

  /// Evaluates whether the BlocListener should react to a state transition.
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

  /// Handles incoming [state] changes emitted by [EliteMasteryBloc].
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

  /// Handles an incorrect answer submission, playing haptics/audio and notifying [EliteMasteryBloc].
  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    submitSharedWrongAnswer(quest: quest, userAnswer: userAnswer);
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(false));
  }

  /// Handles a correct answer submission, celebrating and notifying [EliteMasteryBloc].
  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    submitSharedCorrectAnswer();
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
  }

  /// Dispatches a request to proceed to the next elite mastery quest.
  void dispatchNextQuestion() =>
      context.read<EliteMasteryBloc>().add(const NextEliteQuestion());

  /// Dispatches a hint consumption event to [EliteMasteryBloc].
  void dispatchHintUsed() =>
      context.read<EliteMasteryBloc>().add(const MarkEliteHintUsed());
}
