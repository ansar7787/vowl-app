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
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';

/// Shared mixin for all listening game screen states.
///
/// Eliminates the copy-pasted listener logic, ValueNotifier declarations,
/// and `_submitWrongAnswer` patterns that were duplicated across every
/// listening game screen (audio_multiple_choice, sound_image_match,
/// audio_sentence_order, audio_fill_blanks, ambient_id).
///
/// ## Usage
/// ```dart
/// class _MyScreenState extends State<MyScreen>
///     with ListeningGameScreenMixin {
///   @override
///   GameSubtype get gameType => widget.gameType;
///   @override
///   int get level => widget.level;
///   @override
///   String get completionTitle => 'SONIC RADAR!';
///
///   @override
///   void onQuestionReset() {
///     // Reset any screen-specific state (e.g. selectedIndex, rotation).
///   }
/// }
/// ```
mixin ListeningGameScreenMixin<T extends StatefulWidget> on State<T> {
  // ── Abstract getters that each screen MUST provide ──────────────────────

  /// The game subtype (e.g. `GameSubtype.audioMultipleChoice`).
  GameSubtype get gameType;

  /// The current level number.
  int get level;

  /// Title shown on the completion dialog (e.g. 'SONIC RADAR!').
  String getCompletionTitle(BuildContext context);

  // ── Shared services ────────────────────────────────────────────────────

  late final HapticService hapticService = di.sl<HapticService>();
  late final SoundService soundService = di.sl<SoundService>();

  // ── Shared ValueNotifiers ──────────────────────────────────────────────

  final ValueNotifier<bool> isAnsweredNotifier = ValueNotifier(false);
  final ValueNotifier<bool?> isCorrectNotifier = ValueNotifier(null);
  final ValueNotifier<bool> showConfettiNotifier = ValueNotifier(false);

  // ── Change-tracking ────────────────────────────────────────────────────

  int lastProcessedIndex = -1;
  int? lastLives;

  /// Optional timer key — screens that use a `SpeedChallengeTimer` should
  /// set this in `initState` so the mixin can auto-start/stop it.
  GlobalKey<SpeedChallengeTimerState>? timerKey;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Call this from your `initState` after `super.initState()`.
  void initListeningGame() {
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: gameType, level: level),
    );
  }

  /// Call this from your `dispose` before `super.dispose()`.
  void disposeListeningGame() {
    isAnsweredNotifier.dispose();
    isCorrectNotifier.dispose();
    showConfettiNotifier.dispose();
  }

  // ── BlocConsumer listener (shared across all screens) ──────────────────

  /// Use this as the `listener` of your `BlocConsumer<ListeningBloc, ListeningState>`.
  void onListeningStateChanged(BuildContext context, ListeningState state) {
    if (state is ListeningLoaded) {
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
        onQuestionReset();
      } else if (state.answerStatus.isAnswered && !isAnsweredNotifier.value) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = state.answerStatus.asBoolOrNull;
      }
      lastLives = state.livesRemaining;
    }
    if (state is ListeningGameComplete) {
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

  /// Called when the mixin resets for a new question. Override this to
  /// clear any screen-specific state (selected index, rotation, etc.).
  void onQuestionReset() {}

  // ── Shared wrong answer / timeout handler ──────────────────────────────

  /// Submits a wrong answer. Used for timeouts and incorrect selections.
  ///
  /// Automatically handles: haptic, sound, error journal, local state,
  /// and dispatching [SubmitAnswer(false)] to the bloc.
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
    context.read<ListeningBloc>().add(SubmitAnswer(false));
  }

  /// Submits a correct answer. Handles haptic, sound, local state,
  /// and dispatching [SubmitAnswer(true)] to the bloc.
  void submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();

    hapticService.success();
    soundService.playCorrect();
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = true;
    context.read<ListeningBloc>().add(SubmitAnswer(true));
  }

  // ── Convenience accessors ──────────────────────────────────────────────

  /// Dispatches [NextQuestion] to the listening bloc.
  void dispatchNextQuestion() =>
      context.read<ListeningBloc>().add(const NextQuestion());

  /// Dispatches [ListeningHintUsed] to the listening bloc.
  void dispatchHintUsed() =>
      context.read<ListeningBloc>().add(const ListeningHintUsed());
}
