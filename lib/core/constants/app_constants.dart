class AppConstants {
  /// The total number of levels available across all game modes.
  /// Calculation: 100 levels per game mode x ~200 items each (or similar scaling).
  /// This number should be updated whenever new curriculum content is added.
  static const int totalCurriculumLevels = 20000;
  
  /// The limit for leaderboard fetching to maintain performance.
  static const int leaderboardLimit = 50;
  
  /// Duration for premium haptic feedback loops.
  static const int hapticFeedbackDelayMs = 600;
}
