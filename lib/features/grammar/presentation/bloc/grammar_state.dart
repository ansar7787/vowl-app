import 'package:equatable/equatable.dart';
import '../../domain/entities/grammar_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Answer status enum
// ---------------------------------------------------------------------------

/// Replaces the previous `bool? lastAnswerCorrect` tri-state.
///
/// Using an enum over a nullable bool gives:
/// - Named, self-documenting values instead of `true / false / null`
/// - Exhaustive `switch` support with compiler-enforced coverage
/// - Clean `copyWith` (no null-sentinel hack required)
/// - Extension helpers for common checks
enum AnswerStatus {
  /// No answer has been submitted — the user is still deciding.
  unanswered,

  /// The submitted answer was correct.
  correct,

  /// The submitted answer was incorrect.
  incorrect;

  // --- Convenience getters ---

  /// True for [correct] or [incorrect]; false for [unanswered].
  bool get isAnswered => this != unanswered;

  bool get isCorrect => this == correct;
  bool get isIncorrect => this == incorrect;

  /// Maps to a nullable bool for widgets that expose a [bool?] API boundary
  /// (e.g. GrammarBaseLayout.isCorrect).
  bool? get asBoolOrNull => switch (this) {
    AnswerStatus.unanswered => null,
    AnswerStatus.correct => true,
    AnswerStatus.incorrect => false,
  };
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Base class for all grammar BLoC states.
abstract class GrammarState extends Equatable implements GameStateBase {
  /// Base const constructor for [GrammarState].
  const GrammarState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

/// Initial state emitted when the grammar session is launched or reset.
class GrammarInitial extends GrammarState implements GameInitialState {
  /// Creates a [GrammarInitial] state.
  const GrammarInitial();
}

/// Loading state emitted while fetching grammar quests from cache or cloud storage.
class GrammarLoading extends GrammarState implements GameLoadingState {
  /// Creates a [GrammarLoading] state.
  const GrammarLoading();
}

/// Active gameplay state containing loaded grammar quests and player session progress.
class GrammarLoaded extends GrammarState implements GameLoadedState {
  /// Immutable list of grammar quests for this session.
  final List<GrammarQuest> quests;

  @override
  final int currentIndex;

  @override
  final int livesRemaining;

  /// Status of the most recently submitted answer for the current question.
  final AnswerStatus answerStatus;

  @override
  bool? get lastAnswerCorrect => answerStatus.asBoolOrNull;

  @override
  final bool hintUsed;

  /// Number of incorrect attempts on the current question.
  final int wrongCount;

  @override
  final bool isFinalFailure;

  /// Creates a [GrammarLoaded] state instance.
  GrammarLoaded({
    required List<GrammarQuest> quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  }) : quests = List.unmodifiable(quests);

  /// Returns the current quest.
  ///
  /// Fires an assertion in debug builds if [currentIndex] is out of bounds —
  /// this always indicates a state-machine bug and should never happen in
  /// production.
  GrammarQuest get currentQuest {
    assert(
      currentIndex >= 0 && currentIndex < quests.length,
      'currentIndex ($currentIndex) is out of bounds for '
      'quests.length (${quests.length})',
    );
    return quests[currentIndex];
  }

  @override
  GrammarQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

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

  /// Returns a new [GrammarLoaded] state with updated properties.
  GrammarLoaded copyWith({
    List<GrammarQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return GrammarLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      answerStatus: answerStatus ?? this.answerStatus,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

/// Error state emitted when a failure occurs during grammar gameplay or data fetching.
class GrammarError extends GrammarState implements GameErrorState {
  @override
  final String message;

  /// Internal diagnostic detail for debugging.
  final String? technicalError;

  /// Creates a [GrammarError] state.
  const GrammarError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// Completion state emitted when the learner successfully finishes all quests in a grammar level.
class GrammarGameComplete extends GrammarState implements GameCompleteState {
  @override
  final int xpEarned;

  @override
  final int coinsEarned;

  /// Total number of questions completed in this session.
  final int questCount;

  /// Creates a [GrammarGameComplete] state with earned rewards.
  const GrammarGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// Game over state emitted when the learner runs out of lives in a grammar level.
class GrammarGameOver extends GrammarState implements GameOverState {
  /// Quests that were loaded when game over occurred.
  final List<GrammarQuest> quests;

  /// Index of the question at which the game was lost.
  final int currentIndex;

  @override
  int get livesRemaining => 0;

  /// Creates a [GrammarGameOver] state.
  GrammarGameOver({
    required List<GrammarQuest> quests,
    required this.currentIndex,
  }) : quests = List.unmodifiable(quests);

  @override
  List<Object?> get props => [quests, currentIndex];
}
