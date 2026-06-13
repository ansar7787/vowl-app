import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/reading_quest.dart';


// ---------------------------------------------------------------------------
// copyWith sentinel
// ---------------------------------------------------------------------------

/// Distinguishes "caller omitted lastAnswerCorrect" from
/// "caller explicitly passed null" in [ReadingLoaded.copyWith].
const _kCopyWithUndefined = Object();

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

abstract class ReadingState extends Equatable {
  const ReadingState();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// Concrete states
// ---------------------------------------------------------------------------

/// Initial state before any quests are loaded.
class ReadingInitial extends ReadingState {
  const ReadingInitial();
}

/// Quests are being fetched from the repository.
class ReadingLoading extends ReadingState {
  const ReadingLoading();
}

/// Quests loaded; the game loop is active.
class ReadingLoaded extends ReadingState {
  final List<ReadingQuest> quests;
  final int currentIndex;
  final int livesRemaining;

  /// `null`  — question not yet answered this turn.
  /// `true`  — player answered correctly.
  /// `false` — player answered incorrectly.
  final bool? lastAnswerCorrect;

  final bool hintUsed;

  /// Consecutive wrong-answer count for the current question.
  /// Resets to 0 after [ReadingGameConfig.wrongAnswersBeforeFinal] misses.
  final int wrongCount;

  /// True when the correct answer has been revealed and the player
  /// must tap context.tr('common.continue_text') to move on (question re-queued at the end).
  final bool isFinalFailure;

  /// Always valid while in this state — [currentIndex] is guarded by the BLoC.
  ReadingQuest get currentQuest => quests[currentIndex];

  const ReadingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
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
    Object? lastAnswerCorrect = _kCopyWithUndefined,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return ReadingLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: identical(lastAnswerCorrect, _kCopyWithUndefined)
          ? this.lastAnswerCorrect
          : lastAnswerCorrect as bool?,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

/// A non-recoverable error occurred (network failure, empty data, etc.).
class ReadingError extends ReadingState {
  /// User-safe message suitable for display in the UI.
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
class ReadingGameComplete extends ReadingState {
  final int xpEarned;
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
class ReadingGameOver extends ReadingState {
  final List<ReadingQuest> quests;
  final int currentIndex;

  const ReadingGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
