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
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';

mixin AccentGameScreenMixin<T extends StatefulWidget> on State<T> {
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

  void initAccentGame() {
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: gameType, level: level),
    );
  }

  void disposeAccentGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
  }

  bool accentListenWhen(AccentState prev, AccentState curr) {
    if (curr is AccentGameComplete && prev is! AccentGameComplete) return true;
    if (curr is AccentGameOver && prev is! AccentGameOver) return true;
    if (curr is AccentLoaded && prev is! AccentLoaded) return true;
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is AccentLoaded &&
        curr is AccentLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onAccentStateChanged(BuildContext context, AccentState state) {
    if (state is AccentLoaded) {
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
    if (state is AccentGameComplete) {
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
    context.read<AccentBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<AccentBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<AccentBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<AccentBloc>().add(const AccentHintUsed());
}
