import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// =============================================================================
// Speaking Events
// =============================================================================

/// Base class for all events dispatched to [SpeakingBloc].
abstract class SpeakingEvent extends Equatable {
  /// Base const constructor for speaking events.
  const SpeakingEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches quests for a given [gameType] and [level].
///
/// [gameType] is now strongly typed as [GameSubtype] — no more silent
/// string-to-enum fallback. Update all dispatch sites accordingly.
class FetchSpeakingQuests extends SpeakingEvent {
  /// Speaking subgame variant identifier.
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Creates a [FetchSpeakingQuests] event.
  const FetchSpeakingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Submits the player's answer for the current quest.
class SubmitAnswer extends SpeakingEvent {
  /// Whether the user's spoken answer was judged correct.
  final bool isCorrect;

  /// Creates a [SubmitAnswer] event.
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances to the next quest after feedback is acknowledged.
class NextQuestion extends SpeakingEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Resets the entire level back to [SpeakingInitial].
class RestartLevel extends SpeakingEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

/// Marks the hint as consumed for the current quest.
class SpeakingHintUsed extends SpeakingEvent {
  /// Creates a [SpeakingHintUsed] event.
  const SpeakingHintUsed();
}

/// Resets feedback state so the player can reattempt the current quest.
class RetryCurrentQuestion extends SpeakingEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

/// Restores one life from a [SpeakingGameOver] state (e.g. after watching an ad).
class RestoreLife extends SpeakingEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}

/// Grants additional hints after an in-app purchase or reward.
///
/// (team): Implement optimistic balance update. Currently a no-op;
/// balance is managed server-side and reflected via auth reload.
class AddHint extends SpeakingEvent {
  /// Number of hints to increment.
  final int count;

  /// Creates an [AddHint] event with [count].
  const AddHint(this.count);

  @override
  List<Object?> get props => [count];
}
