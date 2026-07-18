part of 'elite_mastery_bloc.dart';

abstract class EliteMasteryState extends Equatable {
  const EliteMasteryState();

  /// Natively resolves lives for all states to eliminate UI ternary fallback logic.
  int get livesRemaining => 3;

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
  @override
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool isHintVisible;
  final bool isHintUsed;
  final int wrongCount;
  final bool isFinalFailure;
  final List<int> removedIndices;
  final bool isLetterRevealed;

  /// Returns the quest at [currentIndex].
  ///
  /// FIX: previously a bare `quests[currentIndex]`. In correct operation the
  /// BLoC always keeps `currentIndex` inside bounds, but this getter is also
  /// reached from places that construct or copy an [EliteMasteryLoaded]
  /// outside the BLoC's own transitions (e.g. the screen layer building a
  /// dimmed background state from [EliteMasteryGameOver]). A future
  /// off-by-one there — or a regression in the BLoC itself — would otherwise
  /// surface as an opaque `RangeError` crash in the middle of a widget build.
  /// The `assert` still fails loudly in debug/QA builds so the underlying
  /// bug gets caught before release; the clamp keeps release builds showing
  /// the last valid quest instead of crashing.
  EliteMasteryQuest get currentQuest {
    assert(
      quests.isNotEmpty,
      'EliteMasteryLoaded.quests must never be empty — a load failure '
      'should surface as EliteMasteryError instead of an empty list.',
    );
    if (quests.isEmpty) {
      throw StateError(
        'EliteMasteryLoaded.currentQuest was accessed with an empty quests '
        'list. This indicates a bug in the data layer or bloc — a load '
        'failure should have produced EliteMasteryError instead.',
      );
    }
    return quests[currentIndex.clamp(0, quests.length - 1)];
  }

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

/// Stable, localization-friendly cause codes for [EliteMasteryError].
///
/// The BLoC/data layer cannot depend on `BuildContext` or localization
/// (that would break Clean Architecture's layer boundaries), so it can't
/// call `context.tr(...)` itself. Instead it tags the error with one of
/// these codes; the presentation layer (see `EliteBaseLayout`) maps a known
/// code to a fully localized string, and falls back to [EliteMasteryError.message]
/// only for [unknown] — e.g. a message built from an unexpected exception
/// whose text can't be predicted ahead of time.
enum EliteMasteryErrorReason {
  /// Cause doesn't map to a known, localizable case — show [EliteMasteryError.message]
  /// as-is (English fallback).
  unknown,

  /// The repository call itself failed (parse error, missing asset, etc).
  loadFailed,

  /// The repository succeeded but returned zero quests for this level.
  noQuestsForLevel,
}

class EliteMasteryError extends EliteMasteryState {
  final String message;

  /// See [EliteMasteryErrorReason]. Defaults to [EliteMasteryErrorReason.unknown]
  /// so existing call sites that only pass [message] keep their current
  /// behavior unchanged.
  final EliteMasteryErrorReason reason;

  const EliteMasteryError(
    this.message, {
    this.reason = EliteMasteryErrorReason.unknown,
  });

  @override
  List<Object?> get props => [message, reason];
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

  @override
  int get livesRemaining => 0;

  const EliteMasteryGameOver({
    this.gameType,
    this.level,
    required this.quests,
    required this.currentIndex,
  });

  @override
  List<Object?> get props => [gameType, level, quests, currentIndex];
}
