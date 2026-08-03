import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../../domain/entities/writing_quest.dart';

import 'package:vowl/core/presentation/bloc/game_state_base.dart';

// ---------------------------------------------------------------------------
// Writing Feature — States
// Single responsibility: only state definitions live here.
//
// ARCHITECTURE FIX: gameType and level have been moved from mutable instance
// fields on WritingBloc into the state itself. This eliminates a race condition
// where FetchWritingQuests could overwrite the fields before a concurrent
// NextQuestion handler reads them, and keeps each state fully self-contained.
// ---------------------------------------------------------------------------

abstract class WritingState extends Equatable implements GameStateBase {
  const WritingState();

  @override
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

/// Initial state before any quests are fetched.
class WritingInitial extends WritingState implements GameInitialState {
  const WritingInitial();
}

/// Quest fetch in progress.
class WritingLoading extends WritingState implements GameLoadingState {
  const WritingLoading();
}

/// Quests loaded and gameplay is active.
class WritingLoaded extends WritingState implements GameLoadedState {
  final List<WritingQuest> quests;
  @override
  final int currentIndex;
  @override
  final int livesRemaining;
  @override
  final bool? lastAnswerCorrect;
  @override
  final bool hintUsed;
  final int wrongCount;
  @override
  final bool isFinalFailure;

  // FIX: Moved from mutable WritingBloc instance fields — state is now
  // self-contained and safe under concurrent event delivery.
  final GameSubtype gameType;
  final int level;

  WritingQuest get currentQuest => quests[currentIndex];

  @override
  WritingQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  int get totalQuests => quests.length;

  const WritingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    required this.gameType,
    required this.level,
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
    gameType,
    level,
  ];

  WritingLoaded copyWith({
    List<WritingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    // Explicitly nullable so callers can clear lastAnswerCorrect back to null.
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    GameSubtype? gameType,
    int? level,
  }) {
    return WritingLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
    );
  }
}

/// Unrecoverable fetch or runtime error.
class WritingError extends WritingState implements GameErrorState {
  /// User-facing message. Never expose [technicalError] to the UI.
  @override
  final String message;

  /// Internal detail for crash analytics only.
  final String? technicalError;

  const WritingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// Level successfully completed.
class WritingGameComplete extends WritingState implements GameCompleteState {
  @override
  final int xpEarned;
  @override
  final int coinsEarned;
  final int questCount;
  // Retained for analytics and result screen routing.
  final GameSubtype gameType;
  final int level;

  const WritingGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [
    xpEarned,
    coinsEarned,
    questCount,
    gameType,
    level,
  ];
}

/// All lives exhausted. Carries enough data to restore if the user pays to continue.
class WritingGameOver extends WritingState implements GameOverState {
  final List<WritingQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;

  @override
  int get livesRemaining => 0;

  const WritingGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
