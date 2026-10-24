import 'package:vowl/core/presentation/bloc/game_state_base.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/entities/roleplay_quest.dart';

/// Represents the status of the current question's answer submission.
/// Replaces the previous `bool? lastAnswerCorrect` tri-state.
enum AnswerStatus {
  /// Question has not yet received a response.
  unanswered,

  /// Submitted response was evaluated as correct.
  correct,

  /// Submitted response was evaluated as incorrect.
  incorrect;

  /// Whether an answer has been submitted.
  bool get isAnswered => this != AnswerStatus.unanswered;

  /// Tri-state boolean representation of the answer status.
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

// ── Helper ─────────────────────────────────────────────────────────────────

/// Result record returned by [processWrongAnswer].
typedef WrongAnswerResult = ({
  int newLives,
  int newWrongCount,
  bool isFinalFailure,
  List<RoleplayQuest> updatedQuests,
});

/// Single source of truth for wrong-answer state transitions.
///
/// Used by both [SelectDialogueChoice] and [SubmitAnswer] handlers to
/// ensure the logic never diverges between the two paths.
WrongAnswerResult processWrongAnswer(RoleplayLoaded state) {
  final newLives = state.livesRemaining - 1;
  final newWrongCount = state.wrongCount + 1;
  final isFinalDueToWrongCount = newWrongCount >= kRoleplayMaxWrongAttempts;
  final isFinalFailure = isFinalDueToWrongCount || newLives <= 0;

  // Only append the Mastery Loop quest when the player still has lives,
  // is not already at the last question, and hasn't already queued it.
  final isNotLastQuestion = state.currentIndex < state.quests.length - 1;
  final notAlreadyAppended = !state.quests
      .sublist(state.currentIndex + 1)
      .any((q) => q.id == state.currentQuest.id);
  final shouldAppend = isFinalDueToWrongCount &&
      newLives > 0 &&
      isNotLastQuestion &&
      notAlreadyAppended;

  var updatedQuests = state.quests;
  if (shouldAppend) {
    updatedQuests = List<RoleplayQuest>.from(state.quests)
      ..add(state.currentQuest);
  }

  return (
    newLives: newLives,
    // Reset counter when the cap is hit so the re-queued attempt starts fresh.
    newWrongCount: isFinalDueToWrongCount ? 0 : newWrongCount,
    isFinalFailure: isFinalFailure,
    updatedQuests: updatedQuests,
  );
}

// ── State hierarchy ────────────────────────────────────────────────────────
//
// Standard abstract class hierarchy — compatible with all Dart / Flutter
// versions. If your project targets Dart 3.0+ you can optionally add the
// `sealed` modifier to RoleplayState for exhaustive switch checking.

/// Root state class for roleplay gameplay sessions.
abstract class RoleplayState extends Equatable implements GameStateBase {
  /// Const constructor for sub-classes.
  const RoleplayState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  @override
  int get livesRemaining => kRoleplayDefaultLives;

  @override
  List<Object?> get props => [];
}

// ── Transient states ───────────────────────────────────────────────────────

/// Initial state before quest data has been loaded.
class RoleplayInitial extends RoleplayState implements GameInitialState {
  /// Creates a [RoleplayInitial] state.
  const RoleplayInitial();
}

/// Loading state emitted while fetching quest data.
class RoleplayLoading extends RoleplayState implements GameLoadingState {
  /// Creates a [RoleplayLoading] state.
  const RoleplayLoading();
}

// ── Error state ────────────────────────────────────────────────────────────

/// Error state emitted when quest fetching or processing fails.
class RoleplayError extends RoleplayState implements GameErrorState {
  /// Creates a [RoleplayError] state with a user-facing [message] and optional [technicalError].
  const RoleplayError(this.message, {this.technicalError});

  @override
  final String message;

  /// Populated for logging purposes only.
  /// **Never surface this field in the production UI.**
  final String? technicalError;

  @override
  List<Object?> get props => [message, technicalError];
}

// ── Active game state ──────────────────────────────────────────────────────

/// Active playing state containing loaded quests and player progress.
class RoleplayLoaded extends RoleplayState implements GameLoadedState {
  /// Creates a [RoleplayLoaded] state.
  const RoleplayLoaded({
    required this.quests,
    required this.currentIndex,
    this.currentNodeId,
    required this.livesRemaining,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.errorMessage,
    required this.gameType,
    required this.level,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.bonusCoinsEarned = 0,
  });

  /// All quests queued for the current level.
  final List<RoleplayQuest> quests;

  @override
  final int currentIndex;

  /// Identifier of the active node in a branching dialogue tree.
  final String? currentNodeId;

  @override
  final int livesRemaining;

  /// Replaces `lastAnswerCorrect`. Defaults to `unanswered`.
  final AnswerStatus answerStatus;

  /// Legacy accessor for backward compatibility in parts of the UI layer.
  @override
  bool? get lastAnswerCorrect => answerStatus.asBoolOrNull;

  @override
  final bool hintUsed;

  /// Optional error message to display in the UI.
  final String? errorMessage;

  /// Subtype of the active roleplay game.
  final GameSubtype gameType;

  /// Current game level index.
  final int level;

  /// Consecutive wrong attempt count on the current quest.
  final int wrongCount;

  @override
  final bool isFinalFailure;

  /// Bonus coins accumulated from verbal confirmations (e.g., SpeakToConfirmOverlay).
  /// Bundled into [updateUserRewards] at level completion to prevent Firestore
  /// security rule rate-limit collisions (2s minimum interval).
  final int bonusCoinsEarned;

  /// Active quest being attempted.
  RoleplayQuest get currentQuest => quests[currentIndex];

  @override
  RoleplayQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  /// Active dialogue node resolved from [currentQuest] and [currentNodeId].
  DialogueNode? get currentNode =>
      currentQuest.dialogues?[currentNodeId ?? 'start'];

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    currentNodeId,
    livesRemaining,
    answerStatus,
    hintUsed,
    errorMessage,
    gameType,
    level,
    wrongCount,
    isFinalFailure,
    bonusCoinsEarned,
  ];

  /// Creates a copy of this state with specified fields replaced.
  RoleplayLoaded copyWith({
    List<RoleplayQuest>? quests,
    int? currentIndex,
    String? currentNodeId,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    String? errorMessage,
    GameSubtype? gameType,
    int? level,
    int? wrongCount,
    bool? isFinalFailure,
    int? bonusCoinsEarned,
  }) => RoleplayLoaded(
    quests: quests ?? this.quests,
    currentIndex: currentIndex ?? this.currentIndex,
    currentNodeId: currentNodeId ?? this.currentNodeId,
    livesRemaining: livesRemaining ?? this.livesRemaining,
    answerStatus: answerStatus ?? AnswerStatus.unanswered,
    hintUsed: hintUsed ?? this.hintUsed,
    errorMessage: errorMessage,
    gameType: gameType ?? this.gameType,
    level: level ?? this.level,
    wrongCount: wrongCount ?? this.wrongCount,
    isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    bonusCoinsEarned: bonusCoinsEarned ?? this.bonusCoinsEarned,
  );
}

// ── Terminal states ────────────────────────────────────────────────────────

/// Terminal state emitted when all quests in the level have been completed successfully.
class RoleplayGameComplete extends RoleplayState implements GameCompleteState {
  /// Creates a [RoleplayGameComplete] state.
  const RoleplayGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
    required this.lastState,
  });

  @override
  final int xpEarned;
  @override
  final int coinsEarned;

  /// Total count of quests completed in this level.
  final int questCount;

  /// Snapshot of the loaded state at the moment of completion, used by
  /// the UI to continue rendering the final question while the dialog shows.
  final RoleplayLoaded lastState;

  @override
  // Exclude lastState from equality to avoid expensive deep comparison;
  // a completion event is effectively unique per session.
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// Terminal state emitted when the player exhausts all remaining lives.
class RoleplayGameOver extends RoleplayState implements GameOverState {
  /// Creates a [RoleplayGameOver] state.
  const RoleplayGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  /// List of quests at the point of game over.
  final List<RoleplayQuest> quests;

  /// Index of the failing quest.
  final int currentIndex;

  /// Subtype of the active game.
  final GameSubtype gameType;

  /// Level index.
  final int level;

  @override
  int get livesRemaining => 0;

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
