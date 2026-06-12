import 'package:equatable/equatable.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_event.dart';

// ─── Base state ───────────────────────────────────────────────────────────────

abstract class VocabularyState extends Equatable {
  const VocabularyState();

  @override
  List<Object?> get props => [];
}

// ─── Concrete states ──────────────────────────────────────────────────────────

/// The BLoC has been created but no fetch has been dispatched yet.
class VocabularyInitial extends VocabularyState {
  const VocabularyInitial();
}

/// A network fetch is in progress.  The UI should show a loading indicator.
class VocabularyLoading extends VocabularyState {
  const VocabularyLoading();
}

/// Quests are loaded and the player is actively answering questions.
class VocabularyLoaded extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;
  final int livesRemaining;

  /// `true` = last answer correct, `false` = wrong, `null` = no answer yet /
  /// intentionally cleared (use [clearLastAnswerCorrect] in [copyWith]).
  final bool? lastAnswerCorrect;

  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;
  final int hintsAvailable;

  const VocabularyLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.hintsAvailable = 0,
  });

  // ── Safe quest accessors ─────────────────────────────────────────────────

  /// Bounds-checked non-nullable getter.
  ///
  /// Throws a descriptive [AssertionError] in debug mode if the index is
  /// invalid.  Prefer [currentQuestOrNull] in UI code where the index might
  /// be momentarily stale.
  VocabularyQuest get currentQuest {
    assert(
      currentIndex >= 0 && currentIndex < quests.length,
      'currentIndex ($currentIndex) is out of bounds for '
      'quests.length = ${quests.length}',
    );
    return quests[currentIndex];
  }

  /// Safe nullable getter — returns `null` instead of throwing when the
  /// index is out of bounds.  Use this in BlocListener and build methods.
  VocabularyQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  // ── copyWith ─────────────────────────────────────────────────────────────

  /// [clearLastAnswerCorrect] must be passed explicitly as `true` to null-out
  /// [lastAnswerCorrect].  Passing `lastAnswerCorrect: null` preserves the
  /// existing value — avoiding accidental resets at call sites that simply
  /// forget the field.
  VocabularyLoaded copyWith({
    List<VocabularyQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    int? hintsAvailable,
    bool clearLastAnswerCorrect = false,
  }) {
    return VocabularyLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: clearLastAnswerCorrect
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      hintsAvailable: hintsAvailable ?? this.hintsAvailable,
    );
  }

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    hintUsed,
    wrongCount,
    isFinalFailure,
    hintsAvailable,
  ];
}

/// A fetch or persistence operation failed.
class VocabularyError extends VocabularyState {
  /// User-facing message — safe to display in UI.
  final String message;

  /// Internal diagnostic detail — must NEVER be rendered in production UI or
  /// sent to analytics without sanitisation.
  final String? technicalError;

  const VocabularyError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

/// All quests answered successfully — rewards have been persisted.
class VocabularyGameComplete extends VocabularyState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;

  const VocabularyGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

/// The player ran out of lives.  Carries enough context for a revive to
/// restore the session via [RestoreLife].
class VocabularyGameOver extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;

  const VocabularyGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
