import 'package:vowl/core/presentation/bloc/game_state_base.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/entities/roleplay_quest.dart';

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

  // Re-queue the current quest only when the wrong-count cap is reached
  // *and* the player still has lives. If lives hit zero the game ends
  // anyway, so re-queueing would be wasted work.
  var updatedQuests = state.quests;
  if (isFinalDueToWrongCount && newLives > 0) {
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

/// Root state class.
abstract class RoleplayState extends Equatable implements GameStateBase {
  const RoleplayState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  @override
  int get livesRemaining => kRoleplayDefaultLives;

  @override
  List<Object?> get props => [];
}

// ── Transient states ───────────────────────────────────────────────────────

class RoleplayInitial extends RoleplayState implements GameInitialState {
  const RoleplayInitial();
}

class RoleplayLoading extends RoleplayState implements GameLoadingState {
  const RoleplayLoading();
}

// ── Error state ────────────────────────────────────────────────────────────

// ── Error state ────────────────────────────────────────────────────────────

class RoleplayError extends RoleplayState implements GameErrorState {
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

class RoleplayLoaded extends RoleplayState implements GameLoadedState {
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
  });

  final List<RoleplayQuest> quests;
  @override
  final int currentIndex;
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
  final String? errorMessage;
  final GameSubtype gameType;
  final int level;
  final int wrongCount;
  @override
  final bool isFinalFailure;

  RoleplayQuest get currentQuest => quests[currentIndex];

  @override
  RoleplayQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

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
  ];

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
  );
}

// ── Terminal states ────────────────────────────────────────────────────────

// ── Terminal states ────────────────────────────────────────────────────────

class RoleplayGameComplete extends RoleplayState implements GameCompleteState {
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
  final int questCount;

  /// Snapshot of the loaded state at the moment of completion, used by
  /// the UI to continue rendering the final question while the dialog shows.
  final RoleplayLoaded lastState;

  @override
  // Exclude lastState from equality to avoid expensive deep comparison;
  // a completion event is effectively unique per session.
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class RoleplayGameOver extends RoleplayState implements GameOverState {
  const RoleplayGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  final List<RoleplayQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;

  @override
  int get livesRemaining => 0;

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
