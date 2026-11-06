import 'dart:math';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Difficulty tiers for official Computer/AI opponents in 1v1 Arena.
enum ArenaAiDifficultyTier {
  easy,
  medium,
  hard,
}

/// Advanced 3-Pillar Skill-Based Matchmaking (SBMM) engine for 1v1 Arena AI opponents.
///
/// Evaluates:
/// 1. Player Career Skill / Combat Index (Lifetime duelWinRate and totalDuelsPlayed from Firestore).
/// 2. Player Level & Curriculum Breadth (Level 1 to 200+).
/// 3. Session Momentum / Win Streak (Prevents repeated farming and intended smurfing).
///
/// Adheres to the competitive gaming "55% Flow State" rule, preventing
/// runaway bot farming while preserving encouraging gameplay for novices.
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

  /// 3-Pillar Skill-Based Matchmaking (SBMM) factory.
  ///
  /// Combines:
  /// - Career Win Rate (from Firestore duelWins & duelLosses)
  /// - Player Level (derived from totalExp)
  /// - Session Momentum (consecutive wins in current play session)
  factory ArenaAiOpponent.forPlayer(
    UserEntity user, {
    int consecutiveWins = 0,
    Random? random,
  }) {
    return calculateSkillMatchedOpponent(
      playerLevel: user.level,
      winRate: user.duelWinRate,
      totalDuels: user.totalDuelsPlayed,
      consecutiveWins: consecutiveWins,
      random: random,
    );
  }

  /// Backwards-compatible factory based on player level.
  factory ArenaAiOpponent.forPlayerLevel(int level, {Random? random}) {
    return calculateSkillMatchedOpponent(
      playerLevel: level,
      winRate: 50.0,
      totalDuels: 0,
      consecutiveWins: 0,
      random: random,
    );
  }

  /// Pure mathematical calculation for SBMM opponent selection.
  /// Fully deterministic when injected with a seeded [Random].
  static ArenaAiOpponent calculateSkillMatchedOpponent({
    required int playerLevel,
    double winRate = 50.0,
    int totalDuels = 0,
    int consecutiveWins = 0,
    Random? random,
  }) {
    final rng = random ?? Random();

    // 1. Anti-Farm & High-Skill Protection:
    // If player has a high win rate (>= 70% with 3+ games) OR is on a win streak (>= 2):
    // Easy bots are 100% eliminated!
    final bool canUseEasy = (totalDuels < 3 || winRate < 70.0) && consecutiveWins < 2;

    // 2. Level Score (Weight: 40%) -> Range: 10.0 to 100.0
    final double levelScore = (playerLevel * 3.5).clamp(10.0, 100.0);

    // 3. Win Rate Score (Weight: 45%) -> Range: 10.0 to 100.0
    // If fewer than 3 games played, player is in calibration mode (neutral 50.0)
    final double winRateScore = (totalDuels >= 3)
        ? winRate.clamp(10.0, 100.0)
        : 50.0;

    // 4. Streak Bonus (Weight: 15%) -> Range: 0.0 to 30.0
    final double streakBonus = (consecutiveWins * 15.0).clamp(0.0, 30.0);

    // Composite Skill Index: 0.0 to 100.0
    final double compositeSkill = (levelScore * 0.40) +
        (winRateScore * 0.45) +
        (streakBonus * 0.15);

    // Probabilistic Roll (0 to 99)
    final int roll = rng.nextInt(100);

    final ArenaAiDifficultyTier chosenTier;

    if (!canUseEasy) {
      // Competitive / Anti-Farm Bracket: 0% Easy (CANNOT FARM!)
      if (compositeSkill >= 60.0) {
        // High Master: 70% Hard, 30% Medium
        chosenTier = (roll < 70) ? ArenaAiDifficultyTier.hard : ArenaAiDifficultyTier.medium;
      } else {
        // Balanced Competitive: 45% Hard, 55% Medium
        chosenTier = (roll < 45) ? ArenaAiDifficultyTier.hard : ArenaAiDifficultyTier.medium;
      }
    } else {
      // Standard Bracket for Novices / Casual Players:
      if (compositeSkill < 40.0) {
        // Novice Bracket (Lv 1-5 or struggling): 70% Easy, 25% Medium, 5% Hard
        if (roll < 70) {
          chosenTier = ArenaAiDifficultyTier.easy;
        } else if (roll < 95) {
          chosenTier = ArenaAiDifficultyTier.medium;
        } else {
          chosenTier = ArenaAiDifficultyTier.hard;
        }
      } else {
        // Intermediate Bracket: 30% Easy, 50% Medium, 20% Hard
        if (roll < 30) {
          chosenTier = ArenaAiDifficultyTier.easy;
        } else if (roll < 80) {
          chosenTier = ArenaAiDifficultyTier.medium;
        } else {
          chosenTier = ArenaAiDifficultyTier.hard;
        }
      }
    }

    return _buildOpponentForTier(chosenTier, rng);
  }

  static ArenaAiOpponent _buildOpponentForTier(
    ArenaAiDifficultyTier tier,
    Random rng,
  ) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        // Accuracy: 62% to 68% with micro-jitter
        final rawAcc = (0.62 + (rng.nextDouble() * 0.06)).clamp(0.60, 0.68);
        return ArenaAiOpponent(
          id: 'computer_easy',
          displayName: 'Computer',
          tierLabel: 'EASY',
          tier: ArenaAiDifficultyTier.easy,
          accuracy: double.parse(rawAcc.toStringAsFixed(2)),
          minResponseSeconds: 3,
          maxResponseSeconds: 5,
        );
      case ArenaAiDifficultyTier.medium:
        // Accuracy: 76% to 82% with micro-jitter
        final rawAcc = (0.76 + (rng.nextDouble() * 0.06)).clamp(0.75, 0.82);
        return ArenaAiOpponent(
          id: 'computer_medium',
          displayName: 'Computer',
          tierLabel: 'MEDIUM',
          tier: ArenaAiDifficultyTier.medium,
          accuracy: double.parse(rawAcc.toStringAsFixed(2)),
          minResponseSeconds: 2,
          maxResponseSeconds: 4,
        );
      case ArenaAiDifficultyTier.hard:
        // Accuracy: 88% to 94% with micro-jitter
        final rawAcc = (0.88 + (rng.nextDouble() * 0.06)).clamp(0.88, 0.94);
        return ArenaAiOpponent(
          id: 'computer_hard',
          displayName: 'Computer',
          tierLabel: 'HARD',
          tier: ArenaAiDifficultyTier.hard,
          accuracy: double.parse(rawAcc.toStringAsFixed(2)),
          minResponseSeconds: 2,
          maxResponseSeconds: 3,
        );
    }
  }
}
