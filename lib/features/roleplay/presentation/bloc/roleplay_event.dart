import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/entities/roleplay_quest.dart';

// All BLoC events for the Roleplay feature.
// Kept in a dedicated file so the events contract can be read and reviewed
// without scrolling through state definitions or bloc logic.

// ── Lifecycle ──────────────────────────────────────────────────────────────

/// Triggers a fresh load of quests for [gameType] at [level].
class FetchRoleplayQuests extends RoleplayEvent {
  const FetchRoleplayQuests({required this.gameType, required this.level});

  final GameSubtype gameType;
  final int level;

  @override
  List<Object?> get props => [gameType, level];
}

/// Resets the feature to its initial state (e.g. on screen re-entry).
class RestartLevel extends RoleplayEvent {
  const RestartLevel();
}

// ── Dialogue-tree path (scene-based roleplay) ──────────────────────────────

/// The player chose a dialogue option in a branching-conversation quest.
class SelectDialogueChoice extends RoleplayEvent {
  const SelectDialogueChoice(this.choice);

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
  const SubmitAnswer(this.isCorrect);

  final bool isCorrect;

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances the quest index, or completes the level if all quests are done.
class NextQuestion extends RoleplayEvent {
  const NextQuestion();
}

/// Clears the current answer so the player can retry without advancing.
class RetryCurrentQuestion extends RoleplayEvent {
  const RetryCurrentQuestion();
}

// ── Hint ───────────────────────────────────────────────────────────────────

/// The player spent a hint token to reveal the hint for the current quest.
class RoleplayHintUsed extends RoleplayEvent {
  const RoleplayHintUsed();
}

// ── Game over recovery ─────────────────────────────────────────────────────

/// The player used a life-restore to continue from a game-over state.
class RestoreLife extends RoleplayEvent {
  const RestoreLife();
}

// ── Tutor Pass ─────────────────────────────────────────────────────────────

/// The player invoked the tutor pass (I spoke correctly).
class RoleplayTutorPass extends RoleplayEvent {
  const RoleplayTutorPass();
}

// ── Speaking Bonus ─────────────────────────────────────────────────────────

class RoleplaySpeakConfirmed extends RoleplayEvent {
  const RoleplaySpeakConfirmed(this.bonusCoins);
  final int bonusCoins;

  @override
  List<Object?> get props => [bonusCoins];
}

// ── Preloading ─────────────────────────────────────────────────────────────

/// Fires a background preload for the next batch of quests.
/// Should not modify UI state on its own.
class PreloadNextBatch extends RoleplayEvent {
  const PreloadNextBatch({required this.gameType, required this.currentLevel});

  final GameSubtype gameType;
  final int currentLevel;

  @override
  List<Object?> get props => [gameType, currentLevel];
}

// ── Base class ─────────────────────────────────────────────────────────────

abstract class RoleplayEvent extends Equatable {
  const RoleplayEvent();

  @override
  List<Object?> get props => [];
}
