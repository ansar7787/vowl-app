import 'package:equatable/equatable.dart';

/// Base class for all reading feature events.
abstract class ReadingEvent extends Equatable {
  const ReadingEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch quests for [gameType] at [level] from the repository.
class FetchReadingQuests extends ReadingEvent {
  //  Narrow [gameType] from dynamic → GameSubtype once all call-sites
  // have been migrated. Keeping dynamic preserves backward compatibility.
  final dynamic gameType;
  final int level;

  const FetchReadingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Player submitted an answer; [isCorrect] reflects whether it was right.
class SubmitAnswer extends ReadingEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Player tapped "Continue" / "Try Again" to advance the game loop.
class NextQuestion extends ReadingEvent {
  const NextQuestion();
}

/// Player chose to restart the level from the beginning.
class RestartLevel extends ReadingEvent {
  const RestartLevel();
}

/// Player activated the hint for the current question.
class ReadingHintUsed extends ReadingEvent {
  const ReadingHintUsed();
}

/// UI requests a retry of the current question (resets answer state).
class RetryCurrentQuestion extends ReadingEvent {
  const RetryCurrentQuestion();
}

/// Player spent a life-restore token to continue from the Game-Over screen.
class RestoreLife extends ReadingEvent {
  const RestoreLife();
}
