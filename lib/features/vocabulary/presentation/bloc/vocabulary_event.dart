import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// ─── Reward constants ─────────────────────────────────────────────────────────

/// Central reward constants for the vocabulary feature.
///
/// Extracted here (alongside events) so they are available to both the BLoC
/// and any presentation-layer widgets that need to read them without importing
/// the full bloc file.
class VocabularyRewardConstants {
  const VocabularyRewardConstants._();

  static const int baseXp = 10;
  static const int baseCoins = 10;
  static const int initialLives = 3;
  static const int reviveLives = 1;
  static const int maxQuestsPerLevel = 3;
  static const int wrongCountBeforeMasteryLoop = 2;
  static const String masteryBadgeId = 'vocabulary_master';
}

// ─── Base event ───────────────────────────────────────────────────────────────

abstract class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object?> get props => [];
}

// ─── Concrete events ──────────────────────────────────────────────────────────

/// Triggers a network fetch for quests matching [gameType] and [level].
class FetchVocabularyQuests extends VocabularyEvent {
  final GameSubtype gameType;
  final int level;

  const FetchVocabularyQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Records whether the player answered the current quest correctly.
class SubmitAnswer extends VocabularyEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Advances to the next quest or triggers level-complete when on the last quest.
class NextQuestion extends VocabularyEvent {
  const NextQuestion();
}

/// Resets the current quest state for a retry attempt.
class RetryCurrentQuestion extends VocabularyEvent {
  const RetryCurrentQuestion();
}

/// Re-fetches quests for the current game type and level.
class RestartLevel extends VocabularyEvent {
  const RestartLevel();
}

/// Marks the hint as used and deducts one hint from the economy.
class VocabularyHintUsed extends VocabularyEvent {
  const VocabularyHintUsed();
}

/// Restores one life after the player uses a revive on game-over.
class RestoreLife extends VocabularyEvent {
  const RestoreLife();
}

/// Adds [count] hints to the player's available hint pool.
class AddHint extends VocabularyEvent {
  final int count;

  const AddHint(this.count);

  @override
  List<Object?> get props => [count];
}
