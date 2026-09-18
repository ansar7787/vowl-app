import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';

mixin EliteMasteryGameScreenMixin<T extends StatefulWidget> on State<T> {
  GameSubtype get gameType;
  int get level;
  String getCompletionTitle(BuildContext context);

  late final HapticService hapticService = di.sl<HapticService>();
  late final SoundService soundService = di.sl<SoundService>();

  final ValueNotifier<bool> isAnsweredNotifier = ValueNotifier(false);
  final ValueNotifier<bool?> isCorrectNotifier = ValueNotifier(null);
  final ValueNotifier<bool> showConfettiNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isFirstStagePassedNotifier = ValueNotifier(false);

  int lastProcessedIndex = -1;
  int? lastLives;
  GlobalKey<SpeedChallengeTimerState>? timerKey;

  void initEliteMasteryGame() {
    context.read<EliteMasteryBloc>().add(
      FetchEliteMasteryQuests(gameType: gameType, level: level),
    );
  }

  void disposeEliteMasteryGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
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
      final isNewQuestion = state.currentIndex != lastProcessedIndex;
      final isRetry =
          isAnsweredNotifier.value && !state.answerStatus.isAnswered;
      final livesChanged =
          lastLives != null && state.livesRemaining > lastLives!;

      if (isNewQuestion || isRetry || livesChanged) {
        lastProcessedIndex = state.currentIndex;
        isAnsweredNotifier.value = false;
        timerKey?.currentState?.start();
        isCorrectNotifier.value = null;
        isFirstStagePassedNotifier.value = false;
        onQuestionReset();
      } else if (state.answerStatus.isAnswered && !isAnsweredNotifier.value) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = state.answerStatus.asBoolOrNull;
      }
      lastLives = state.livesRemaining;
    }
    if (state is EliteMasteryGameComplete) {
      showConfettiNotifier.value = true;
      GameDialogHelper.showCompletion(
        context,
        xp: state.xpEarned,
        coins: state.coinsEarned,
        title: getCompletionTitle(context),
        enableDoubleUp: true,
      );
    }
  }

  void onQuestionReset() {}

  void submitWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.error();
    soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      ErrorJournalCollector.record(
        userId: authState.user!.id,
        gameType: gameType.name,
        question: quest.textToSpeak ?? getCompletionTitle(context),
        userAnswer: userAnswer ?? '[Timeout]',
        correctAnswer:
            quest.correctAnswer ??
            (quest.options != null && quest.options!.isNotEmpty
                ? quest.options![quest.correctAnswerIndex ?? 0]
                : ''),
        level: level,
      );
    }
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<EliteMasteryBloc>().add(const SubmitEliteAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<EliteMasteryBloc>().add(const NextEliteQuestion());
  void dispatchHintUsed() =>
      context.read<EliteMasteryBloc>().add(const MarkEliteHintUsed());
}
