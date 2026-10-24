import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/entities/roleplay_quest.dart';

// All BLoC events for the Roleplay feature.
// Kept in a dedicated file so the events contract can be read and reviewed
// without scrolling through state definitions or bloc logic.

// ── Lifecycle ──────────────────────────────────────────────────────────────

/// Triggers a fresh load of quests for [gameType] at [level].
class FetchRoleplayQuests extends RoleplayEvent {
  /// Creates a [FetchRoleplayQuests] event.
  const FetchRoleplayQuests({required this.gameType, required this.level});

  /// Roleplay game subtype to load.
  final GameSubtype gameType;

  /// Level index to load.
  final int level;

  @override
  List<Object?> get props => [gameType, level];
}

/// Resets the feature to its initial state (e.g. on screen re-entry).
class RestartLevel extends RoleplayEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

// ── Dialogue-tree path (scene-based roleplay) ──────────────────────────────

/// The player chose a dialogue option in a branching-conversation quest.
class SelectDialogueChoice extends RoleplayEvent {
  /// Creates a [SelectDialogueChoice] event with the selected [choice].
  const SelectDialogueChoice(this.choice);

  /// Selected dialogue choice node.
  final DialogueChoice choice;

  @override
  List<Object?> get props => [choice];
}

// ── Options-list path (multiple-choice roleplay) ───────────────────────────

/// The player confirmed their multiple-choice answer.
///
/// Audio / haptic feedback is the bloc's responsibility — do not fire
/// sound or haptics in the UI layer for this flow.
class SubmitAnswer extends RoleplayEvent {
  /// Creates a [SubmitAnswer] event indicating whether the answer [isCorrect].
  const SubmitAnswer(this.isCorrect);

  /// Whether the submitted answer was correct.
  final bool isCorrect;

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances the quest index, or completes the level if all quests are done.
class NextQuestion extends RoleplayEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Clears the current answer so the player can retry without advancing.
class RetryCurrentQuestion extends RoleplayEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

// ── Hint ───────────────────────────────────────────────────────────────────

/// The player spent a hint token to reveal the hint for the current quest.
class RoleplayHintUsed extends RoleplayEvent {
  /// Creates a [RoleplayHintUsed] event.
  const RoleplayHintUsed();
}

// ── Game over recovery ─────────────────────────────────────────────────────

/// The player used a life-restore to continue from a game-over state.
class RestoreLife extends RoleplayEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}

// ── Speaking Bonus ─────────────────────────────────────────────────────────

/// Event dispatched when a user confirms speech practice.
class RoleplaySpeakConfirmed extends RoleplayEvent {
  /// Creates a [RoleplaySpeakConfirmed] event with [bonusCoins].
  const RoleplaySpeakConfirmed(this.bonusCoins);

  /// Bonus coins to record.
  final int bonusCoins;

  @override
  List<Object?> get props => [bonusCoins];
}

// ── Preloading ─────────────────────────────────────────────────────────────

/// Fires a background preload for the next batch of quests.
/// Should not modify UI state on its own.
class PreloadNextBatch extends RoleplayEvent {
  /// Creates a [PreloadNextBatch] event.
  const PreloadNextBatch({required this.gameType, required this.currentLevel});

  /// Roleplay game subtype to preload.
  final GameSubtype gameType;

  /// Current level index being played.
  final int currentLevel;

  @override
  List<Object?> get props => [gameType, currentLevel];
}

// ── Base class ─────────────────────────────────────────────────────────────

/// Base class for all roleplay BLoC events.
abstract class RoleplayEvent extends Equatable {
  /// Const constructor for sub-classes.
  const RoleplayEvent();

  @override
  List<Object?> get props => [];
}
