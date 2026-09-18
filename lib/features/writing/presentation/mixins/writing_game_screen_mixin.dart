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
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';

mixin WritingGameScreenMixin<T extends StatefulWidget> on State<T> {
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

  void initWritingGame() {
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: gameType, level: level),
    );
  }

  void disposeWritingGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
  }

  bool writingListenWhen(WritingState prev, WritingState curr) {
    if (curr is WritingGameComplete && prev is! WritingGameComplete) {
      return true;
    }
    if (curr is WritingGameOver && prev is! WritingGameOver) return true;
    if (curr is WritingLoaded && prev is! WritingLoaded) return true;
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is WritingLoaded &&
        curr is WritingLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onWritingStateChanged(BuildContext context, WritingState state) {
    if (state is WritingLoaded) {
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
    if (state is WritingGameComplete) {
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
    context.read<WritingBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<WritingBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<WritingBloc>().add(const WritingHintUsed());
}
