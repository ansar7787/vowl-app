/// Contract for listening-game analytics events.
///
/// Inject [NoOpListeningAnalytics] in tests and staging; provide a real
/// implementation (Firebase, Mixpanel, …) in production via your DI layer.
abstract class ListeningAnalytics {
  /// Fired when the player answers a question (correct or wrong).
  void onAnswerSubmitted({
    required String gameType,
    required int level,
    required int questionIndex,
    required bool isCorrect,
  });

  /// Fired when the player taps the hint button.
  void onHintUsed({
    required String gameType,
    required int level,
    required int questionIndex,
  });

  /// Fired when the player successfully completes all questions in the level.
  void onLevelComplete({
    required String gameType,
    required int level,
    required int xpEarned,
    required int coinsEarned,
  });

  /// Fired when the player runs out of lives.
  void onGameOver({
    required String gameType,
    required int level,
    required int questionsCompleted,
  });

  /// Fired when the player restores a life via a rewarded action.
  void onLifeRestored({required String gameType, required int level});
}

/// Default no-op implementation — safe to use in any environment.
class NoOpListeningAnalytics implements ListeningAnalytics {
  const NoOpListeningAnalytics();

  @override
  void onAnswerSubmitted({
    required String gameType,
    required int level,
    required int questionIndex,
    required bool isCorrect,
  }) {}

  @override
  void onHintUsed({
    required String gameType,
    required int level,
    required int questionIndex,
  }) {}

  @override
  void onLevelComplete({
    required String gameType,
    required int level,
    required int xpEarned,
    required int coinsEarned,
  }) {}

  @override
  void onGameOver({
    required String gameType,
    required int level,
    required int questionsCompleted,
  }) {}

  @override
  void onLifeRestored({required String gameType, required int level}) {}
}
