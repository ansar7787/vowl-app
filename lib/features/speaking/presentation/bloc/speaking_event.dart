import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// =============================================================================
// Speaking Events
// =============================================================================

abstract class SpeakingEvent extends Equatable {
  const SpeakingEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches quests for a given [gameType] and [level].
///
/// [gameType] is now strongly typed as [GameSubtype] — no more silent
/// string-to-enum fallback. Update all dispatch sites accordingly.
class FetchSpeakingQuests extends SpeakingEvent {
  final GameSubtype gameType;
  final int level;

  const FetchSpeakingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Submits the player's answer for the current quest.
class SubmitAnswer extends SpeakingEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances to the next quest after feedback is acknowledged.
class NextQuestion extends SpeakingEvent {
  const NextQuestion();
}

/// Resets the entire level back to [SpeakingInitial].
class RestartLevel extends SpeakingEvent {
  const RestartLevel();
}

/// Marks the hint as consumed for the current quest.
class SpeakingHintUsed extends SpeakingEvent {
  const SpeakingHintUsed();
}

/// Resets feedback state so the player can reattempt the current quest.
class RetryCurrentQuestion extends SpeakingEvent {
  const RetryCurrentQuestion();
}

/// Restores one life from a [SpeakingGameOver] state (e.g. after watching an ad).
class RestoreLife extends SpeakingEvent {
  const RestoreLife();
}

/// Grants additional hints after an in-app purchase or reward.
///
/// (team): Implement optimistic balance update. Currently a no-op;
/// balance is managed server-side and reflected via auth reload.
class AddHint extends SpeakingEvent {
  final int count;

  const AddHint(this.count);

  @override
  List<Object?> get props => [count];
}

/// Called by the AI Tutor to pass the student on the current quest,
/// restoring one life and clearing the mastery-loop re-queue.
class SpeakingTutorPass extends SpeakingEvent {
  const SpeakingTutorPass();
}
