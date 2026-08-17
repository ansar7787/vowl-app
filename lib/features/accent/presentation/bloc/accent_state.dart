import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Base state
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

abstract class AccentState extends Equatable implements GameStateBase {
  const AccentState();

  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// AccentInitial
// ---------------------------------------------------------------------------

/// Blank slate — emitted on launch and after [RestartLevel].
class AccentInitial extends AccentState implements GameInitialState {
  const AccentInitial();
}

// ---------------------------------------------------------------------------
// AccentLoading
// ---------------------------------------------------------------------------

/// Quests are being fetched from the network or local cache.
class AccentLoading extends AccentState implements GameLoadingState {
  const AccentLoading();
}

// ---------------------------------------------------------------------------
// AccentLoaded
// ---------------------------------------------------------------------------

/// Active game session with at least one quest available.
class AccentLoaded extends AccentState implements GameLoadedState {
  final List<AccentQuest> quests;
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
  final GameSubtype gameType;
  final int level;

  /// How many wrong answers the player has given for the current quest.
  /// Resets to 0 when advancing to the next quest or when [isFinalFailure].
  final int wrongCount;

  /// `true` when the player has failed this quest twice (Mastery Loop trigger)
  /// or when lives have been exhausted.
  @override
  final bool isFinalFailure;

  AccentQuest get currentQuest => quests[currentIndex];

  @override
  AccentQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  const AccentLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    required this.gameType,
    required this.level,
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
    gameType,
    level,
    wrongCount,
    isFinalFailure,
  ];

  /// Returns a new [AccentLoaded] with the given fields overridden.
  ///
  /// [lastAnswerCorrect] is intentionally NOT null-coalesced: passing `null`
  /// explicitly clears the answered state (e.g. moving to next question).
  AccentLoaded copyWith({
    List<AccentQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    GameSubtype? gameType,
    int? level,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return AccentLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      answerStatus:
          answerStatus ?? AnswerStatus.unanswered, // enum override intentional
      hintUsed: hintUsed ?? this.hintUsed,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

// ---------------------------------------------------------------------------
// AccentError
// ---------------------------------------------------------------------------

class AccentError extends AccentState implements GameErrorState {
  @override
  final String message;

  /// Raw technical detail for debugging.
  /// **Never display [technicalError] directly in production UI** — it may
  /// contain internal stack information. Gate it behind `kDebugMode`.
  final String? technicalError;

  const AccentError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

// ---------------------------------------------------------------------------
// AccentGameComplete
// ---------------------------------------------------------------------------

class AccentGameComplete extends AccentState implements GameCompleteState {
  @override
  final int xpEarned;
  @override
  final int coinsEarned;
  final int questCount;

  /// Snapshot of the game state at the moment of completion.
  /// Allows the results screen to re-read lives, streak, etc.
  final AccentLoaded lastState;

  const AccentGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
    required this.lastState,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount, lastState];
}

// ---------------------------------------------------------------------------
// AccentGameOver
// ---------------------------------------------------------------------------

class AccentGameOver extends AccentState implements GameOverState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;

  @override
  int get livesRemaining => 0;

  const AccentGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
