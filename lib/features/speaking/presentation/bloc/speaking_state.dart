import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// =============================================================================
// Speaking States
// =============================================================================

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

abstract class SpeakingState extends Equatable implements GameStateBase {
  const SpeakingState();

  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

/// No quests loaded yet; the screen is awaiting a [FetchSpeakingQuests] event.
class SpeakingInitial extends SpeakingState implements GameInitialState {
  const SpeakingInitial();
}

/// Quests are being fetched from the data layer.
class SpeakingLoading extends SpeakingState implements GameLoadingState {
  const SpeakingLoading();
}

/// Quests are loaded and gameplay is active.
///
/// [gameType] and [level] are stored here instead of as mutable fields
/// on [SpeakingBloc] — eliminates the race condition where [RestartLevel]
/// could leave stale game-type context on the bloc.
class SpeakingLoaded extends SpeakingState implements GameLoadedState {
  final List<SpeakingQuest> quests;
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
  final List<int> removedIndices;
  final bool isLetterRevealed;

  /// Session-immutable: the game type this level belongs to.
  final GameSubtype gameType;

  /// Session-immutable: the level number for reward persistence.
  final int level;

  SpeakingQuest get currentQuest => quests[currentIndex];

  @override
  SpeakingQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  const SpeakingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    required this.gameType,
    required this.level,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.removedIndices = const [],
    this.isLetterRevealed = false,
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
    removedIndices,
    isLetterRevealed,
    gameType,
    level,
  ];

  SpeakingLoaded copyWith({
    List<SpeakingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    List<int>? removedIndices,
    bool? isLetterRevealed,
    // gameType and level are session-immutable; intentionally excluded.
  }) {
    return SpeakingLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      gameType: gameType,
      level: level,
      answerStatus: answerStatus ?? AnswerStatus.unanswered,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      removedIndices: removedIndices ?? this.removedIndices,
      isLetterRevealed: isLetterRevealed ?? this.isLetterRevealed,
    );
  }
}

/// A non-fatal error occurred (network failure, empty quest list, etc.).
class SpeakingError extends SpeakingState implements GameErrorState {
  /// User-facing message shown in the error UI.
  @override
  final String message;

  /// Internal detail for logging only — never displayed in the UI.
  final String? technicalError;

  const SpeakingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// The player successfully completed all quests in the level.
class SpeakingGameComplete extends SpeakingState implements GameCompleteState {
  @override
  final int xpEarned;
  @override
  final int coinsEarned;
  final int questCount;

  const SpeakingGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// The player ran out of lives.
///
/// Carries [gameType] and [level] so that restore-life flows (tutor pass,
/// ad reward) can reconstruct a valid [SpeakingLoaded] state without
/// requiring mutable fields on the BLoC.
class SpeakingGameOver extends SpeakingState implements GameOverState {
  final List<SpeakingQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;

  @override
  int get livesRemaining => 0;

  const SpeakingGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
