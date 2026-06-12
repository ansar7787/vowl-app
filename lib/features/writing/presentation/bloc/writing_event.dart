import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Writing Feature — Events
// Single responsibility: only event definitions live here.
// ---------------------------------------------------------------------------

abstract class WritingEvent extends Equatable {
  const WritingEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial quest load for a given game subtype and level.
class FetchWritingQuests extends WritingEvent {
  final dynamic gameType;
  final int level;

  const FetchWritingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Submitted when the user finishes answering the current question.
class SubmitAnswer extends WritingEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances to the next question (or completes the level).
class NextQuestion extends WritingEvent {
  const NextQuestion();
}

/// Resets the bloc to [WritingInitial] so the level can be re-fetched.
class RestartLevel extends WritingEvent {
  const RestartLevel();
}

/// Marks a hint as consumed for the current question.
class WritingHintUsed extends WritingEvent {
  const WritingHintUsed();
}

/// Re-enters the question loop without changing any other state.
class RetryCurrentQuestion extends WritingEvent {
  const RetryCurrentQuestion();
}

/// Restores one life after a game-over, returning to [WritingLoaded].
class RestoreLife extends WritingEvent {
  const RestoreLife();
}
