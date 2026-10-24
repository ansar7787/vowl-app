import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Base state
// ---------------------------------------------------------------------------

/// Represents the status of the current question's answer submission.
enum AnswerStatus {
  /// No answer has been submitted for this trial yet.
  unanswered,

  /// The submitted answer was evaluated as correct.
  correct,

  /// The submitted answer was evaluated as incorrect.
  incorrect;

  /// Whether an answer has been submitted (either correct or incorrect).
  bool get isAnswered => this != AnswerStatus.unanswered;

  /// Returns `true` for correct, `false` for incorrect, and `null` for unanswered.
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

/// Abstract base class for all accent training BLoC states.
abstract class AccentState extends Equatable implements GameStateBase {
  /// Base const constructor for [AccentState].
  const AccentState();

  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// AccentInitial
// ---------------------------------------------------------------------------

/// Initial blank state emitted on launch and after level reset.
class AccentInitial extends AccentState implements GameInitialState {
  /// Creates an [AccentInitial] state.
  const AccentInitial();
}

// ---------------------------------------------------------------------------
// AccentLoading
// ---------------------------------------------------------------------------

/// State indicating quests are being fetched from local cache or remote storage.
class AccentLoading extends AccentState implements GameLoadingState {
  /// Creates an [AccentLoading] state.
  const AccentLoading();
}

// ---------------------------------------------------------------------------
// AccentLoaded
// ---------------------------------------------------------------------------

/// Active game session with at least one quest available.
class AccentLoaded extends AccentState implements GameLoadedState {
  /// The collection of quests for the active level.
  final List<AccentQuest> quests;

  @override
  final int currentIndex;

  @override
  final int livesRemaining;

  /// Status of the active question's evaluation.
  final AnswerStatus answerStatus;

  /// Legacy accessor for backward compatibility in parts of the UI layer.
  @override
  bool? get lastAnswerCorrect => answerStatus.asBoolOrNull;

  @override
  final bool hintUsed;

  /// The active accent game subtype.
  final GameSubtype gameType;

  /// The current level index.
  final int level;

  /// How many wrong answers the player has given for the current quest.
  final int wrongCount;

  /// Whether the player has failed this quest twice or exhausted lives.
  @override
  final bool isFinalFailure;

  /// The currently active [AccentQuest].
  AccentQuest get currentQuest => quests[currentIndex];

  @override
  AccentQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  /// Creates an [AccentLoaded] session state.
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

/// State indicating an error occurred during accent session execution.
class AccentError extends AccentState implements GameErrorState {
  @override
  final String message;

  /// Raw technical detail for debugging.
  final String? technicalError;

  /// Creates an [AccentError] state with a human-readable [message].
  const AccentError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

// ---------------------------------------------------------------------------
// AccentGameComplete
// ---------------------------------------------------------------------------

/// State emitted upon successfully clearing all quests in the level.
class AccentGameComplete extends AccentState implements GameCompleteState {
  @override
  final int xpEarned;

  @override
  final int coinsEarned;

  /// Total number of questions completed during the session.
  final int questCount;

  /// Snapshot of the game state at the moment of completion.
  final AccentLoaded lastState;

  /// Creates an [AccentGameComplete] state with reward and telemetry metrics.
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

/// State emitted when the player runs out of lives before finishing the level.
class AccentGameOver extends AccentState implements GameOverState {
  /// The quest collection active when game over was reached.
  final List<AccentQuest> quests;

  /// The quest index at failure.
  final int currentIndex;

  /// The active game subtype.
  final GameSubtype gameType;

  /// The current level index.
  final int level;

  @override
  int get livesRemaining => 0;

  /// Creates an [AccentGameOver] terminal state.
  const AccentGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
