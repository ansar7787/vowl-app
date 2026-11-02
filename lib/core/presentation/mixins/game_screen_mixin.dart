import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/praise_service.dart';
import 'package:vowl/core/utils/app_lifecycle_handler.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Shared stateful screen mixin coordinating game lifecycle, answer evaluation,
/// optimistic level unlocking, timer management, and victory confetti.
mixin GameScreenMixin<T extends StatefulWidget> on State<T> {
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
  AppLifecycleListener? _gameLifecycleListener;

  /// Tracks question progression within the active 3-question level (1, 2, 3) for pitch scaling.
  int _levelQuestionIndex = 0;

  /// Tracks macro session streak across consecutive levels until a mistake is made.
  static int _sessionHotStreak = 0;

  void initGameLifecycle() {
    _gameLifecycleListener = AppLifecycleHandler.createListener(
      onPause: onGamePaused,
      onResume: onGameResumed,
    );
  }

  void onGamePaused() {
    timerKey?.currentState?.pause();
  }

  void onGameResumed() {
    if (!isAnsweredNotifier.value) {
      timerKey?.currentState?.resume();
    }
  }

  void disposeGame() {
    _gameLifecycleListener?.dispose();
    try {
      soundService.stopTts();
      soundService.stopAudio();
    } catch (_) {}
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
  }

  void onQuestionReset() {}

  void handleGameComplete(
    BuildContext context, {
    required int xpEarned,
    required int coinsEarned,
  }) {
    showConfettiNotifier.value = true;

    // Optimistically unlock the next level in AuthBloc so map state reflects
    // the completion immediately upon navigation, before or while Firestore transactions run.
    try {
      context.read<AuthBloc>().add(
        AuthLevelCompletedOptimistic(
          gameType: gameType.name,
          level: level,
        ),
      );
    } catch (_) {
      // Defensive fallback in case AuthBloc is not provided in isolated widget tests
    }

    GameDialogHelper.showCompletion(
      context,
      xp: xpEarned,
      coins: coinsEarned,
      title: getCompletionTitle(context),
      enableDoubleUp: true,
      gameType: gameType.name,
      level: level,
    );
  }

  void handleStateUpdate({
    required int currentIndex,
    required int livesRemaining,
    required bool isAnswered,
    required bool? isCorrect,
  }) {
    final isNewQuestion = currentIndex != lastProcessedIndex;
    final isRetry = isAnsweredNotifier.value && !isAnswered;
    final livesChanged = lastLives != null && livesRemaining > lastLives!;

    if (isNewQuestion || isRetry || livesChanged) {
      if (isNewQuestion && timerKey != null) {
        timerKey = GlobalKey<SpeedChallengeTimerState>();
      }
      if (isNewQuestion && currentIndex == 0) {
        _levelQuestionIndex = 0;
      }
      lastProcessedIndex = currentIndex;
      isAnsweredNotifier.value = isAnswered;
      if (!isAnswered) {
        timerKey?.currentState?.start();
        isCorrectNotifier.value = null;
        isFirstStagePassedNotifier.value = false;
        onQuestionReset();
      } else {
        isCorrectNotifier.value = isCorrect;
      }
    } else if (isAnswered && !isAnsweredNotifier.value) {
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = isCorrect;
    }
    lastLives = livesRemaining;
  }

  void submitSharedWrongAnswer({required GameQuest quest, String? userAnswer}) {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    _levelQuestionIndex = 0;
    _sessionHotStreak = 0;

    hapticService.error();
    soundService.playWrong();

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      ErrorJournalCollector.record(
        userId: authState.user!.id,
        gameType: gameType.name,
        question:
            quest.targetWord ??
            quest.sentence ??
            quest.question ??
            quest.textToSpeak ??
            getCompletionTitle(context),
        userAnswer: userAnswer ?? '[Timeout]',
        correctAnswer:
            quest.correctAnswer ??
            (quest.options != null && quest.options!.isNotEmpty
                ? quest.options![quest.correctAnswerIndex ?? 0]
                : ''),
        level: level,
        options: quest.options,
      );
    }
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = false;
  }

  void submitSharedCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    _levelQuestionIndex++;
    _sessionHotStreak++;

    hapticService.success();
    // Dual-Layer Dopamine: Micro 3-step pitch ladder (Q1: 1.00x, Q2: 1.12x, Q3: 1.25x)
    soundService.playCorrect(comboStep: _levelQuestionIndex);

    // Macro Hot Streak Celebrations across levels (5 in a row, 10 in a row)
    if (_sessionHotStreak == 5) {
      di.sl<PraiseService>().givePraise(context: PraiseContext.hotStreak5);
    } else if (_sessionHotStreak == 10) {
      di.sl<PraiseService>().givePraise(context: PraiseContext.hotStreak10);
    }

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
  }
}
