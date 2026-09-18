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
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

/// Shared mixin for all vocabulary game screen states.
/// Eliminates the copy-pasted listener logic, ValueNotifier declarations,
/// and `_submitWrongAnswer` patterns that were duplicated across every screen.
mixin VocabularyGameScreenMixin<T extends StatefulWidget> on State<T> {
  // ── Abstract getters that each screen MUST provide ──────────────────────

  /// The game subtype.
  GameSubtype get gameType;

  /// The current level number.
  int get level;

  /// Title shown on the completion dialog.
  String getCompletionTitle(BuildContext context);

  // ── Shared services ────────────────────────────────────────────────────

  late final HapticService hapticService = di.sl<HapticService>();
  late final SoundService soundService = di.sl<SoundService>();

  // ── Shared ValueNotifiers ──────────────────────────────────────────────

  final ValueNotifier<bool> isAnsweredNotifier = ValueNotifier(false);
  final ValueNotifier<bool?> isCorrectNotifier = ValueNotifier(null);
  final ValueNotifier<bool> showConfettiNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isFirstStagePassedNotifier = ValueNotifier(false);

  // ── Change-tracking ────────────────────────────────────────────────────

  int lastProcessedIndex = -1;
  int? lastLives;

  /// Optional timer key
  GlobalKey<SpeedChallengeTimerState>? timerKey;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  void initVocabularyGame() {
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: gameType, level: level),
    );
  }

  void disposeVocabularyGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
    isFirstStagePassedNotifier.dispose();
  }

  // ── BlocConsumer shared conditions and listeners ────────────────────────

  bool vocabularyListenWhen(VocabularyState prev, VocabularyState curr) {
    if (curr is VocabularyGameComplete && prev is! VocabularyGameComplete) {
      return true;
    }
    if (curr is VocabularyGameOver && prev is! VocabularyGameOver) return true;
    if (curr is VocabularyLoaded && prev is! VocabularyLoaded) return true;
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.answerStatus != curr.answerStatus) {
      return true;
    }
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.currentIndex != curr.currentIndex) {
      return true;
    }
    if (prev is VocabularyLoaded &&
        curr is VocabularyLoaded &&
        prev.livesRemaining != curr.livesRemaining) {
      return true;
    }
    return false;
  }

  void onVocabularyStateChanged(BuildContext context, VocabularyState state) {
    if (state is VocabularyLoaded) {
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
    if (state is VocabularyGameComplete) {
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

  // ── Shared wrong answer / timeout handler ──────────────────────────────

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
    context.read<VocabularyBloc>().add(SubmitAnswer(false));
  }

  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<VocabularyBloc>().add(SubmitAnswer(true));
  }

  void dispatchNextQuestion() =>
      context.read<VocabularyBloc>().add(const NextQuestion());
  void dispatchHintUsed() =>
      context.read<VocabularyBloc>().add(const VocabularyHintUsed());
}
