/// Centralised configuration constants for the grammar quiz feature.
///
/// **Why a constants file?**
/// Magic numbers scattered across BLoC, state, and UI files create silent
/// coupling — changing the quest limit requires hunting every `3` in the
/// codebase. Centralising here makes changes atomic and auditable.
///
/// When the reward system becomes dynamically configurable (e.g. fetched from
/// a remote config service), replace these statics with a
/// `GrammarConfigRepository` and inject it into the BLoC.
abstract final class GrammarConstants {
  /// Number of quests loaded and played per level.
  static const int questsPerLevel = 3;

  /// Starting lives per level session.
  static const int livesPerLevel = 3;

  /// XP awarded on successful level completion.
  static const int xpPerLevel = 10;

  /// Coins awarded on successful level completion.
  static const int coinsPerLevel = 10;

  /// Consecutive wrong answers before a quest is re-queued (mastery loop).
  static const int wrongAnswersBeforeMasteryLoop = 2;

  /// `level % preloadTriggerMod == preloadTriggerMod` triggers next-batch
  /// preloading so the cache is warm before the user reaches the next set.
  static const int preloadTriggerMod = 9;

  /// Delay in milliseconds before the TTS nudge fires after the user drops
  /// to their last life.
  static const int lastLifeNudgeDelayMs = 1200;
}
