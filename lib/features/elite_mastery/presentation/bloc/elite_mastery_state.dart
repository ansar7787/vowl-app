part of 'elite_mastery_bloc.dart';

abstract class EliteMasteryState extends Equatable {
  const EliteMasteryState();

  @override
  List<Object?> get props => [];
}

class EliteMasteryInitial extends EliteMasteryState {
  const EliteMasteryInitial();
}

class EliteMasteryLoading extends EliteMasteryState {
  const EliteMasteryLoading();
}

class EliteMasteryLoaded extends EliteMasteryState {
  /// The game sub-type for this session.
  ///
  /// **Nullable for backward compatibility.** Existing call sites — tests,
  /// mocks, or any screen that constructs this state directly — do not need
  /// updating.  The BLoC always sets this via [FetchEliteMasteryQuests];
  /// `null` only occurs in environments that bypass the BLoC (e.g. unit tests
  /// that create stub states without these fields).
  final GameSubtype? gameType;

  /// Level index for this session. See [gameType] for nullability rationale.
  final int? level;

  final List<EliteMasteryQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool isHintVisible;
  final bool isHintUsed;
  final int wrongCount;
  final bool isFinalFailure;
  final List<int> removedIndices;
  final bool isLetterRevealed;

  EliteMasteryQuest get currentQuest => quests[currentIndex];

  const EliteMasteryLoaded({
    // Optional, not `required`, so pre-existing call sites compile unchanged.
    this.gameType,
    this.level,
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.isHintVisible = false,
    this.isHintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.removedIndices = const [],
    this.isLetterRevealed = false,
  });

  @override
  List<Object?> get props => [
    gameType,
    level,
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    isHintVisible,
    isHintUsed,
    wrongCount,
    isFinalFailure,
    removedIndices,
    isLetterRevealed,
  ];

  /// Returns a copy with the supplied fields replaced.
  ///
  /// Use [resetLastAnswer] to explicitly set [lastAnswerCorrect] back to
  /// `null`.  A dedicated flag is necessary because passing
  /// `lastAnswerCorrect: null` is indistinguishable from "no change".
  EliteMasteryLoaded copyWith({
    GameSubtype? gameType,
    int? level,
    List<EliteMasteryQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? isHintVisible,
    bool? isHintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    List<int>? removedIndices,
    bool? isLetterRevealed,
    bool resetLastAnswer = false,
  }) {
    return EliteMasteryLoaded(
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: resetLastAnswer
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      isHintVisible: isHintVisible ?? this.isHintVisible,
      isHintUsed: isHintUsed ?? this.isHintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      removedIndices: removedIndices ?? this.removedIndices,
      isLetterRevealed: isLetterRevealed ?? this.isLetterRevealed,
    );
  }
}

class EliteMasteryError extends EliteMasteryState {
  final String message;

  const EliteMasteryError(this.message);

  @override
  List<Object?> get props => [message];
}

class EliteMasteryGameComplete extends EliteMasteryState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;

  const EliteMasteryGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class EliteMasteryGameOver extends EliteMasteryState {
  /// See [EliteMasteryLoaded.gameType] for nullability rationale.
  final GameSubtype? gameType;

  /// See [EliteMasteryLoaded.level] for nullability rationale.
  final int? level;

  final List<EliteMasteryQuest> quests;
  final int currentIndex;

  const EliteMasteryGameOver({
    this.gameType,
    this.level,
    required this.quests,
    required this.currentIndex,
  });

  @override
  List<Object?> get props => [gameType, level, quests, currentIndex];
}
