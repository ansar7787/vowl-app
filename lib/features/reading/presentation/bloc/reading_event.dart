import 'package:equatable/equatable.dart';

/// Base class for all reading feature events.
abstract class ReadingEvent extends Equatable {
  /// Abstract const constructor for [ReadingEvent] subclasses.
  const ReadingEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch quests for [gameType] at [level] from the repository.
class FetchReadingQuests extends ReadingEvent {
  //  Narrow [gameType] from dynamic → GameSubtype once all call-sites
  // have been migrated. Keeping dynamic preserves backward compatibility.
  /// The reading game subtype requested.
  final dynamic gameType;

  /// The difficulty or curriculum level of the quests.
  final int level;

  /// Creates a [FetchReadingQuests] event.
  const FetchReadingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Player submitted an answer; [isCorrect] reflects whether it was right.
class SubmitAnswer extends ReadingEvent {
  /// Whether the user's submitted answer is correct.
  final bool isCorrect;

  /// Creates a [SubmitAnswer] event.
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Player tapped continue or try again to advance the game loop.
class NextQuestion extends ReadingEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Player chose to restart the level from the beginning.
class RestartLevel extends ReadingEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

/// Player activated the hint for the current question.
class ReadingHintUsed extends ReadingEvent {
  /// Creates a [ReadingHintUsed] event.
  const ReadingHintUsed();
}

/// UI requests a retry of the current question (resets answer state).
class RetryCurrentQuestion extends ReadingEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

/// Player spent a life-restore token to continue from the Game-Over screen.
class RestoreLife extends ReadingEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}

/// Player confirmed pronunciation or speech in a reading exercise.
class ReadingSpeakConfirmed extends ReadingEvent {
  /// Number of bonus coins awarded upon voice confirmation.
  final int bonusCoins;

  /// Creates a [ReadingSpeakConfirmed] event.
  const ReadingSpeakConfirmed(this.bonusCoins);

  @override
  List<Object?> get props => [bonusCoins];
}
