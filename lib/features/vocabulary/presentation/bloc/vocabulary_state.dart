import 'package:equatable/equatable.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_event.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

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

// ─── Base state ───────────────────────────────────────────────────────────────

abstract class VocabularyState extends Equatable implements GameStateBase {
  const VocabularyState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

// ─── Concrete states ──────────────────────────────────────────────────────────

/// The BLoC has been created but no fetch has been dispatched yet.
class VocabularyInitial extends VocabularyState implements GameInitialState {
  const VocabularyInitial();
}

/// A network fetch is in progress.  The UI should show a loading indicator.
class VocabularyLoading extends VocabularyState implements GameLoadingState {
  const VocabularyLoading();
}

/// Quests are loaded and the player is actively answering questions.
class VocabularyLoaded extends VocabularyState implements GameLoadedState {
  final List<VocabularyQuest> quests;
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
  final int wrongCount;
  @override
  final bool isFinalFailure;
  final int hintsAvailable;

  const VocabularyLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.hintsAvailable = 0,
  });

  // ── Safe quest accessors ─────────────────────────────────────────────────

  /// Bounds-checked non-nullable getter.
  ///
  /// Throws a descriptive [AssertionError] in debug mode if the index is
  /// invalid.  Prefer [currentQuestOrNull] in UI code where the index might
  /// be momentarily stale.
  VocabularyQuest get currentQuest {
    assert(
      currentIndex >= 0 && currentIndex < quests.length,
      'currentIndex ($currentIndex) is out of bounds for '
      'quests.length = ${quests.length}',
    );
    return quests[currentIndex];
  }

  /// Safe nullable getter — returns `null` instead of throwing when the
  /// index is out of bounds.  Use this in BlocListener and build methods.
  @override
  VocabularyQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  // ── copyWith ─────────────────────────────────────────────────────────────

  /// A dedicated flag is no longer necessary because passing AnswerStatus.unanswered
  /// explicitly resets it.
  VocabularyLoaded copyWith({
    List<VocabularyQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    int? hintsAvailable,
  }) {
    return VocabularyLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      answerStatus: answerStatus ?? this.answerStatus,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      hintsAvailable: hintsAvailable ?? this.hintsAvailable,
    );
  }

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    answerStatus,
    hintUsed,
    wrongCount,
    isFinalFailure,
    hintsAvailable,
  ];
}

/// A fetch or persistence operation failed.
class VocabularyError extends VocabularyState implements GameErrorState {
  /// User-facing message — safe to display in UI.
  @override
  final String message;

  /// Internal diagnostic detail — must NEVER be rendered in production UI or
  /// sent to analytics without sanitisation.
  final String? technicalError;

  const VocabularyError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// All quests answered successfully — rewards have been persisted.
class VocabularyGameComplete extends VocabularyState
    implements GameCompleteState {
  @override
  final int xpEarned;
  @override
  final int coinsEarned;
  final int questCount;

  const VocabularyGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// The player ran out of lives.  Carries enough context for a revive to
/// restore the session via [RestoreLife].
class VocabularyGameOver extends VocabularyState implements GameOverState {
  final List<VocabularyQuest> quests;
  final int currentIndex;

  @override
  int get livesRemaining => 0;

  const VocabularyGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
