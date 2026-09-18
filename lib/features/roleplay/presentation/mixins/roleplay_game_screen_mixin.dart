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
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';

mixin RoleplayGameScreenMixin<T extends StatefulWidget> on State<T> {
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

  void initRoleplayGame() {
    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: gameType, level: level),
    );
  }

  void disposeRoleplayGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
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
    if (state is RoleplayGameComplete) {
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
    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<RoleplayBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<RoleplayBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<RoleplayBloc>().add(const RoleplayHintUsed());
}
