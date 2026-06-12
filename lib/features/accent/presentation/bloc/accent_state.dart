import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

// ---------------------------------------------------------------------------
// Base state
// ---------------------------------------------------------------------------

abstract class AccentState extends Equatable {
  const AccentState();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------------------------
// AccentInitial
// ---------------------------------------------------------------------------

/// Blank slate — emitted on launch and after [RestartLevel].
class AccentInitial extends AccentState {
  const AccentInitial();
}

// ---------------------------------------------------------------------------
// AccentLoading
// ---------------------------------------------------------------------------

/// Quests are being fetched from the network or local cache.
class AccentLoading extends AccentState {
  const AccentLoading();
}

// ---------------------------------------------------------------------------
// AccentLoaded
// ---------------------------------------------------------------------------

/// Active game session with at least one quest available.
class AccentLoaded extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final int livesRemaining;

  /// `null`  = no answer submitted yet for this quest.
  /// `true`  = last submitted answer was correct.
  /// `false` = last submitted answer was wrong.
  final bool? lastAnswerCorrect;

  final bool hintUsed;
  final GameSubtype gameType;
  final int level;

  /// How many wrong answers the player has given for the current quest.
  /// Resets to 0 when advancing to the next quest or when [isFinalFailure].
  final int wrongCount;

  /// `true` when the player has failed this quest twice (Mastery Loop trigger)
  /// or when lives have been exhausted.
  final bool isFinalFailure;

  AccentQuest get currentQuest => quests[currentIndex];

  const AccentLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
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
    lastAnswerCorrect,
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
    bool? lastAnswerCorrect,
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
      lastAnswerCorrect: lastAnswerCorrect, // nullable override intentional
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

class AccentError extends AccentState {
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

class AccentGameComplete extends AccentState {
  final int xpEarned;
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

class AccentGameOver extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;

  const AccentGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}
