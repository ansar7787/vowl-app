/// Phase of the Learn → Practice → Mastery cycle.
enum GamePhase {
  learn,
  practice,
  mastery;

  /// Backward-compatible alias for legacy references during migration.
  static const GamePhase test = GamePhase.mastery;

  String get displayName => switch (this) {
    GamePhase.learn => 'LEARN',
    GamePhase.practice => 'PRACTICE',
    GamePhase.mastery => 'MASTERY',
  };

  String get emoji => switch (this) {
    GamePhase.learn => '🧠',
    GamePhase.practice => '✋',
    GamePhase.mastery => '🏆',
  };

  static GamePhase fromString(String? value) {
    if (value == null) return GamePhase.learn;
    return switch (value.toLowerCase().trim()) {
      'learn' => GamePhase.learn,
      'practice' => GamePhase.practice,
      'mastery' || 'test' => GamePhase.mastery,
      _ => GamePhase.learn,
    };
  }
}
