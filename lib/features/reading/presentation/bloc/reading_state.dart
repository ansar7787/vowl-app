import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/reading_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

/// Represents the status of the current question's answer submission.
/// Replaces the previous `bool? lastAnswerCorrect` tri-state.
enum AnswerStatus {
  unanswered,
  correct,
  incorrect;

  bool get isAnswered => this != AnswerStatus.unanswered;

  bool? get asBoolOrNull {
    switch (this) {
      case AnswerStatus.unanswered:
        return null;
      case AnswerStatus.correct:
        return true;
      case AnswerStatus.incorrect:
        return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

abstract class ReadingState extends Equatable implements GameStateBase {
  const ReadingState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// Concrete states
// ---------------------------------------------------------------------------

/// Initial state before any quests are loaded.
class ReadingInitial extends ReadingState implements GameInitialState {
  const ReadingInitial();
}

/// Quests are being fetched from the repository.
class ReadingLoading extends ReadingState implements GameLoadingState {
  const ReadingLoading();
}

/// Quests loaded; the game loop is active.
class ReadingLoaded extends ReadingState implements GameLoadedState {
  final List<ReadingQuest> quests;
  @override
  final int currentIndex;
  @override
  final int livesRemaining;

  /// Replaces `lastAnswerCorrect`. Defaults to `unanswered`.
  final AnswerStatus answerStatus;

  /// Legacy accessor for backward compatibility in parts of the UI layer.
  @override
  bool? get lastAnswerCorrect => answerStatus.asBoolOrNull;

  @override
  final bool hintUsed;

  /// Consecutive wrong-answer count for the current question.
  /// Resets to 0 after [ReadingGameConfig.wrongAnswersBeforeFinal] misses.
  final int wrongCount;

  /// True when the correct answer has been revealed and the player
  /// must tap context.tr('common.continue_text', fallback: 'Continue') to move on (question re-queued at the end).
  @override
  final bool isFinalFailure;

  /// Always valid while in this state — [currentIndex] is guarded by the BLoC.
  ReadingQuest get currentQuest => quests[currentIndex];

  @override
  ReadingQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  const ReadingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    answerStatus,
    hintUsed,
    wrongCount,
    isFinalFailure,
  ];

  /// Returns a copy of this state with the specified fields replaced.
  ///
  /// [lastAnswerCorrect] uses a sentinel default so that omitting the
  /// parameter preserves the current value, while passing `null` explicitly
  /// resets it to "unanswered". This prevents the classic nullable-copyWith
  /// bug where `copyWith(hintUsed: true)` would silently null out
  /// [lastAnswerCorrect].
  ReadingLoaded copyWith({
    List<ReadingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return ReadingLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      answerStatus:
          answerStatus ?? AnswerStatus.unanswered, // enum override intentional
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

/// A non-recoverable error occurred (network failure, empty data, etc.).
class ReadingError extends ReadingState implements GameErrorState {
  /// User-safe message suitable for display in the UI.
  @override
  final String message;

  /// Internal diagnostic detail. Never render this in the UI directly —
  /// use a proper logger. Exposed here for unit tests only.
  @visibleForTesting
  final String? technicalError;

  const ReadingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// All quests answered successfully — level complete.
class ReadingGameComplete extends ReadingState implements GameCompleteState {
  @override
  final int xpEarned;
  @override
  final int coinsEarned;
  final int questCount;

  const ReadingGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// Player ran out of lives before completing all quests.
class ReadingGameOver extends ReadingState implements GameOverState {
  final List<ReadingQuest> quests;
  final int currentIndex;

  @override
  int get livesRemaining => 0;

  const ReadingGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
