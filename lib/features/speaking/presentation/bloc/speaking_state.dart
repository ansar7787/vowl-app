import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

// =============================================================================
// Speaking States
// =============================================================================

abstract class SpeakingState extends Equatable {
  const SpeakingState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  int get livesRemaining => 3;

  @override
  List<Object?> get props => [];
}

/// No quests loaded yet; the screen is awaiting a [FetchSpeakingQuests] event.
class SpeakingInitial extends SpeakingState {
  const SpeakingInitial();
}

/// Quests are being fetched from the data layer.
class SpeakingLoading extends SpeakingState {
  const SpeakingLoading();
}

/// Quests are loaded and gameplay is active.
///
/// [gameType] and [level] are stored here instead of as mutable fields
/// on [SpeakingBloc] — eliminates the race condition where [RestartLevel]
/// could leave stale game-type context on the bloc.
class SpeakingLoaded extends SpeakingState {
  final List<SpeakingQuest> quests;
  final int currentIndex;
  @override
  final int livesRemaining;

  /// `null`  → no answer submitted yet (question is active).
  /// `true`  → last answer was correct (success feedback visible).
  /// `false` → last answer was wrong   (failure feedback visible).
  ///
  /// **copyWith contract:** this field does NOT fall back to `this.value`
  /// when omitted. Omitting it intentionally resets it to `null`.
  /// All call sites that want to preserve the current value must pass it.
  final bool? lastAnswerCorrect;

  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;
  final List<int> removedIndices;
  final bool isLetterRevealed;

  /// Session-immutable: the game type this level belongs to.
  final GameSubtype gameType;

  /// Session-immutable: the level number for reward persistence.
  final int level;

  SpeakingQuest get currentQuest => quests[currentIndex];

  const SpeakingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    required this.gameType,
    required this.level,
    this.lastAnswerCorrect,
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
    lastAnswerCorrect,
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
    bool? lastAnswerCorrect,
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
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      removedIndices: removedIndices ?? this.removedIndices,
      isLetterRevealed: isLetterRevealed ?? this.isLetterRevealed,
    );
  }
}

/// A non-fatal error occurred (network failure, empty quest list, etc.).
class SpeakingError extends SpeakingState {
  /// User-facing message shown in the error UI.
  final String message;

  /// Internal detail for logging only — never displayed in the UI.
  final String? technicalError;

  const SpeakingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// The player successfully completed all quests in the level.
class SpeakingGameComplete extends SpeakingState {
  final int xpEarned;
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
class SpeakingGameOver extends SpeakingState {
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
