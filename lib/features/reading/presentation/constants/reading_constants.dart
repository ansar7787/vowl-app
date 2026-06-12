/// Centralised game-rule constants for the reading feature.
///
/// Defining these in the domain/constants layer means the BLoC, UI, and any
/// future remote-config override all share a single source of truth.
/// To run an A/B test or difficulty experiment, change only this file.
abstract final class ReadingGameConfig {
  ReadingGameConfig._();

  /// Maximum questions loaded per reading session.
  static const int maxQuestsPerSession = 3;

  /// Lives the player starts each level with.
  static const int initialLives = 3;

  /// Wrong answers on a single question before the correct answer is
  /// revealed and the question is appended to the end of the queue.
  static const int wrongAnswersBeforeFinal = 2;

  /// Level number (besides level 1) that triggers the full briefing overlay.
  static const int milestoneBriefingLevel = 100;

  /// XP awarded on successful level completion.
  static const int xpPerLevel = 10;

  /// Coins awarded on successful level completion.
  static const int coinsPerLevel = 10;
}
