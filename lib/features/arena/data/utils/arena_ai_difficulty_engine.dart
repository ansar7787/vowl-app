/// Difficulty tiers for official Computer/AI opponents in 1v1 Arena.
enum ArenaAiDifficultyTier {
  easy,
  medium,
  hard,
}

/// Official Computer/AI opponent calibrated directly against the player's level.
/// Replaces fake human persona disguises with honest, authentic real-world AI tiers.
class ArenaAiOpponent {
  final String id;
  final String displayName;
  final String tierLabel;
  final ArenaAiDifficultyTier tier;
  final double accuracy;
  final int minResponseSeconds;
  final int maxResponseSeconds;

  const ArenaAiOpponent({
    required this.id,
    required this.displayName,
    required this.tierLabel,
    required this.tier,
    required this.accuracy,
    required this.minResponseSeconds,
    required this.maxResponseSeconds,
  });

  /// Calibrates an authentic Computer/AI opponent directly positioned against the player's level.
  factory ArenaAiOpponent.forPlayerLevel(int level) {
    if (level <= 10) {
      return const ArenaAiOpponent(
        id: 'computer_easy',
        displayName: 'Computer',
        tierLabel: 'EASY',
        tier: ArenaAiDifficultyTier.easy,
        accuracy: 0.65,
        minResponseSeconds: 3,
        maxResponseSeconds: 5,
      );
    } else if (level <= 25) {
      return const ArenaAiOpponent(
        id: 'computer_medium',
        displayName: 'Computer',
        tierLabel: 'MEDIUM',
        tier: ArenaAiDifficultyTier.medium,
        accuracy: 0.80,
        minResponseSeconds: 2,
        maxResponseSeconds: 4,
      );
    } else {
      return const ArenaAiOpponent(
        id: 'computer_hard',
        displayName: 'Computer',
        tierLabel: 'HARD',
        tier: ArenaAiDifficultyTier.hard,
        accuracy: 0.90,
        minResponseSeconds: 2,
        maxResponseSeconds: 3,
      );
    }
  }
}

