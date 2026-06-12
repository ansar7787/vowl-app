import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// All event constructors are const so BLoC can skip redundant dispatches
// when the same event object is re-used.

abstract class AccentEvent extends Equatable {
  const AccentEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch and load quests for [gameType] at [level].
class FetchAccentQuests extends AccentEvent {
  final GameSubtype gameType;
  final int level;

  const FetchAccentQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Player submitted an answer. [isCorrect] reflects the evaluation result.
class SubmitAnswer extends AccentEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advance to the next quest (or complete/fail the level).
class NextQuestion extends AccentEvent {
  const NextQuestion();
}

/// Reset to [AccentInitial] and clear the cache.
class RestartLevel extends AccentEvent {
  const RestartLevel();
}

/// Player tapped the hint button.
class AccentHintUsed extends AccentEvent {
  const AccentHintUsed();
}

/// Reset feedback state so the current question can be reattempted.
class RetryCurrentQuestion extends AccentEvent {
  const RetryCurrentQuestion();
}

/// Restore 1 life after watching a rewarded ad or similar.
class RestoreLife extends AccentEvent {
  const RestoreLife();
}

/// Preload quests for the next level in the background.
class PreloadBatch extends AccentEvent {
  final GameSubtype gameType;
  final int currentLevel;

  const PreloadBatch({required this.gameType, required this.currentLevel});

  @override
  List<Object?> get props => [gameType, currentLevel];
}

/// AI tutor has intervened: treat the current question as passed and restore a life.
class AccentTutorPass extends AccentEvent {
  const AccentTutorPass();
}
