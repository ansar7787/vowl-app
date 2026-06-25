import 'dart:async';
import 'package:flutter/widgets.dart';

/// Shared mixin that encapsulates the answer-submission lifecycle previously
/// duplicated across all game-screen State classes.
///
/// ### Responsibilities
/// 1. Guards against double-submission via [_isSubmitting].
/// 2. Calls [onUpdate] synchronously so local visual state updates in one
///    render pass.
/// 3. Dispatches the game event through the [onSubmitEvent] callback (BLoC
///    agnostic — works with any BLoC/Cubit).
/// 4. Schedules a cancellable [Timer] for wrong-answer auto-reset.
/// 5. Provides [cancelResetTimer] so navigation (NextQuestion, GameOver) can
///    abort a pending reset before state is corrupted.
///
/// ### Why sound and haptic calls are NOT here
/// Game BLoCs (e.g., SpeakingBloc, GrammarBloc) call [SoundService] and
/// [HapticService] internally via their singleton GetIt registrations inside
/// `_onSubmitAnswer`. If a screen also called those singletons, the same
/// instance would receive two calls per answer — causing double sound playback
/// and double vibration. Screens own only **visual** state; the BLoC owns all
/// A/V feedback.
///
/// ### Usage
/// ```dart
/// class _MyGameScreenState extends State<MyGameScreen>
///     with GameAnswerHandler {
///
///   @override
///   void initState() {
///     super.initState();
///     initAnswerHandler();
///   }
///
///   @override
///   void dispose() {
///     disposeAnswerHandler();
///     super.dispose();
///   }
///
///   void _handleTap(int index, int correctIndex) {
///     submitAnswer(
///       isCorrect: index == correctIndex,
///       onUpdate: () => setState(() {
///         _selectedIndex = index;
///         _isAnswered = true;
///         _isCorrect = index == correctIndex;
///       }),
///       onSubmitEvent: () => context.read<MyGameBloc>()
///           .add(SubmitAnswer(isCorrect: index == correctIndex)),
///       onReset: () => setState(() {
///         _selectedIndex = null;
///         _isAnswered = false;
///         _isCorrect = false;
///       }),
///     );
///   }
/// }
/// ```
mixin GameAnswerHandler<T extends StatefulWidget> on State<T> {
  Timer? _resetTimer;

  /// Guards against rapid taps before the BLoC has processed the previous
  /// event and updated `lastAnswerCorrect` in state.
  bool _isSubmitting = false;

  /// Whether an answer has been committed for the current question.
  bool isAnswered = false;

  /// `true` = correct, `false` = wrong, `null` = no answer yet.
  bool? isCorrect;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Must be called from [State.initState].
  void initAnswerHandler() {
    _isSubmitting = false;
    isAnswered = false;
    isCorrect = null;
  }

  /// Must be called from [State.dispose] **before** `super.dispose()`.
  void disposeAnswerHandler() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resets local answer state to the "no answer yet" position.
  ///
  /// Call this when advancing to the next question via [cancelResetTimer] +
  /// [resetAnswerState] in sequence.
  void resetAnswerState() {
    isAnswered = false;
    isCorrect = null;
  }

  /// Submits an answer and coordinates local visual state with the BLoC.
  ///
  /// ### Parameters
  /// - [isCorrect]: whether the user's selection matches the correct answer.
  /// - [onUpdate]: called **synchronously** before the BLoC event is
  ///   dispatched. Wrap all local setState mutations here. Do NOT call
  ///   SoundService or HapticService — the BLoC handles A/V feedback.
  /// - [onSubmitEvent]: dispatches the corresponding BLoC event. This is
  ///   intentionally a callback so the mixin stays BLoC-agnostic.
  /// - [onReset]: called after [resetDelay] on a wrong answer. Wrap reset
  ///   state mutations in setState here.
  /// - [resetDelay]: how long to wait before auto-resetting on a wrong answer.
  ///   Defaults to 2 seconds.
  void submitAnswer({
    required bool isCorrect,
    required VoidCallback onUpdate,
    required VoidCallback onSubmitEvent,
    VoidCallback? onReset,
    Duration resetDelay = const Duration(seconds: 2),
  }) {
    if (_isSubmitting) return;
    _isSubmitting = true;

    this.isAnswered = true;
    this.isCorrect = isCorrect;

    // Apply local visual state in a single synchronous pass before the BLoC
    // event so the UI reflects the selection immediately (0-frame latency).
    onUpdate();

    // Dispatch to the BLoC. The BLoC is responsible for: sound, haptics,
    // lives decrement, wrongCount, and isFinalFailure logic.
    // This screen is responsible for: selectedIndex, isAnswered, isCorrect.
    onSubmitEvent();

    if (!isCorrect && onReset != null) {
      // Cancel any previously scheduled reset before scheduling a new one.
      _resetTimer?.cancel();
      _resetTimer = Timer(resetDelay, () {
        if (mounted) {
          this.isAnswered = false;
          this.isCorrect = null;
          onReset();
          _isSubmitting = false;
        }
      });
    } else {
      // Correct answers unlock immediately so the user can tap Next without
      // waiting for a timer to expire.
      _isSubmitting = false;
    }
  }

  /// Cancels any pending auto-reset timer and unlocks submission.
  ///
  /// Call this when [NextQuestion] is dispatched so the timer does not fire
  /// and corrupt state after the question has already advanced.
  ///
  /// Typical call sequence for advancing to the next question:
  /// ```dart
  /// cancelResetTimer();
  /// resetAnswerState();
  /// context.read<MyBloc>().add(const NextQuestion());
  /// ```
  void cancelResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _isSubmitting = false;
  }
}
