import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Writing Feature — Events
// Single responsibility: only event definitions live here.
// ---------------------------------------------------------------------------

/// Base class for all events dispatched to the [WritingBloc].
abstract class WritingEvent extends Equatable {
  /// Const constructor for base event.
  const WritingEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial quest load for a given game subtype and level.
class FetchWritingQuests extends WritingEvent {
  /// Target game subtype.
  final dynamic gameType;

  /// Progression level index.
  final int level;

  /// Creates a [FetchWritingQuests] event.
  const FetchWritingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Submitted when the user finishes answering the current question.
class SubmitAnswer extends WritingEvent {
  /// Whether the user's answer was evaluated as correct.
  final bool isCorrect;

  /// Creates a [SubmitAnswer] event.
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances to the next question (or completes the level).
class NextQuestion extends WritingEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Resets the bloc to [WritingInitial] so the level can be re-fetched.
class RestartLevel extends WritingEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

/// Marks a hint as consumed for the current question.
class WritingHintUsed extends WritingEvent {
  /// Creates a [WritingHintUsed] event.
  const WritingHintUsed();
}

/// Re-enters the question loop without changing any other state.
class RetryCurrentQuestion extends WritingEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

/// Restores one life after a game-over, returning to [WritingLoaded].
class RestoreLife extends WritingEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}
