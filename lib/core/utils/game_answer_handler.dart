import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';

/// Shared mixin that encapsulates the repetitive answer-submission logic
/// previously duplicated across all 9 game-screen State classes.
///
/// ### Why sound and haptic calls are NOT here
///
/// [AccentBloc._onSubmit] already calls [SoundService.playCorrect],
/// [SoundService.playWrong], [HapticService.success], and [HapticService.error]
/// internally. All three of those are registered as singletons in GetIt.
///
/// If a screen ALSO called those methods, the same singleton would receive
/// two calls per answer event — causing double sound playback and double
/// vibration. Screens must only update their local visual state; the BLoC
/// owns all A/V feedback for answer events.
///
/// ### What this mixin does
///
/// 1. Guards against double-submission via [_isSubmitting].
/// 2. Calls [onUpdate] synchronously so local visual state updates in one pass.
/// 3. Dispatches [SubmitAnswer] to [AccentBloc].
/// 4. Schedules a cancellable [Timer] for wrong-answer auto-reset.
/// 5. Provides [cancelResetTimer] so navigation / NextQuestion can abort it.
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
///       context: context,
///       isCorrect: index == correctIndex,
///       onUpdate: () => setState(() {
///         _selectedIndex = index;
///         _isAnswered = true;          // local visual flag
///         _isCorrect = index == correctIndex;
///       }),
///       onReset: () => setState(() {  // called after resetDelay on wrong answer
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

  // Guard to prevent the edge case where a user rapidly taps before the
  // BLoC event is fully processed and lastAnswerCorrect is set in state.
  bool _isSubmitting = false;

  bool isAnswered = false;
  bool? isCorrect;

  /// Must be called from [State.initState].
  void initAnswerHandler() {
    _isSubmitting = false;
    isAnswered = false;
    isCorrect = null;
  }

  /// Must be called from [State.dispose] before `super.dispose()`.
  void disposeAnswerHandler() {
    _resetTimer?.cancel();
    _resetTimer = null;
  }

  /// Resets the local answer state back to the initial state.
  void resetAnswerState() {
    isAnswered = false;
    isCorrect = null;
  }

  /// Submits an answer and coordinates local visual state with the BLoC.
  ///
  /// ### Parameters
  ///
  /// - [context]: current [BuildContext] — used to access [AccentBloc].
  /// - [isCorrect]: `true` if the user's selection matches the correct answer.
  /// - [onUpdate]: called synchronously before the Bloc event is dispatched.
  ///   Wrap all local state mutations in a single `setState(...)` callback here.
  ///   **Do NOT call SoundService or HapticService here** — the BLoC handles them.
  /// - [onReset]: called after [resetDelay] on a wrong answer. Wrap reset
  ///   state mutations in `setState(...)` here.
  /// - [resetDelay]: how long to wait before resetting on a wrong answer.
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

    isAnswered = true;
    this.isCorrect = isCorrect;

    // Apply local visual state in a single synchronous pass.
    onUpdate();

    // Dispatch to the BLoC.
    // The BLoC handles: sound, haptics, lives, wrongCount, isFinalFailure.
    // Screens only handle: selectedIndex, isAnswered, isCorrect (visual state).
    onSubmitEvent();

    if (!isCorrect && onReset != null) {
      _resetTimer?.cancel();
      _resetTimer = Timer(resetDelay, () {
        if (mounted) {
          isAnswered = false;
          this.isCorrect = null;
          onReset();
          _isSubmitting = false;
        }
      });
    } else {
      // For correct answers, unlock immediately so the user can tap Next.
      _isSubmitting = false;
    }
  }

  /// Cancels any pending auto-reset timer and unlocks submission.
  ///
  /// Call this when [NextQuestion] is dispatched so the timer does not
  /// fire and corrupt state after the question has already advanced.
  void cancelResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _isSubmitting = false;
  }
}
