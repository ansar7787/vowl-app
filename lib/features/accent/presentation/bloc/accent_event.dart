import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// All event constructors are const so BLoC can skip redundant dispatches
// when the same event object is re-used.

/// Base class for all accent training BLoC events.
abstract class AccentEvent extends Equatable {
  /// Const base constructor for [AccentEvent].
  const AccentEvent();

  @override
  List<Object?> get props => [];
}

/// Event requesting quests to be fetched for [gameType] at [level].
class FetchAccentQuests extends AccentEvent {
  /// The specific accent game subtype to load.
  final GameSubtype gameType;

  /// The level index being accessed.
  final int level;

  /// Creates a [FetchAccentQuests] event.
  const FetchAccentQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Event dispatched when a user submits an answer.
class SubmitAnswer extends AccentEvent {
  /// Whether the submitted response was assessed as correct.
  final bool isCorrect;

  /// Creates a [SubmitAnswer] event with evaluation result [isCorrect].
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Event dispatched to advance to the next quest item or finalize the session.
class NextQuestion extends AccentEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Event dispatched to restart the active level from the beginning.
class RestartLevel extends AccentEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

/// Event dispatched when the user requests a pedagogical hint.
class AccentHintUsed extends AccentEvent {
  /// Creates an [AccentHintUsed] event.
  const AccentHintUsed();
}

/// Event dispatched to allow the user to retry the active question after failure.
class RetryCurrentQuestion extends AccentEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

/// Event dispatched to replenish one lost life (e.g., via rewarded media).
class RestoreLife extends AccentEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}

/// Event dispatched to trigger background prefetching of the next quest batch.
class PreloadBatch extends AccentEvent {
  /// The target accent game subtype.
  final GameSubtype gameType;

  /// The user's current level index.
  final int currentLevel;

  /// Creates a [PreloadBatch] event.
  const PreloadBatch({required this.gameType, required this.currentLevel});

  @override
  List<Object?> get props => [gameType, currentLevel];
}

/// Event dispatched when the user completes speech verification.
class AccentSpeakConfirmed extends AccentEvent {
  /// Additional reward coins granted for oral repetition.
  final int bonusCoins;

  /// Creates an [AccentSpeakConfirmed] event with [bonusCoins].
  const AccentSpeakConfirmed(this.bonusCoins);

  @override
  List<Object?> get props => [bonusCoins];
}
