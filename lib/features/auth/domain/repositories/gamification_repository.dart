import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

/// Domain contract defining gamification progress, XP, and achievement operations.
///
/// All write operations execute as Firestore transactions to guarantee atomicity
/// and eliminate concurrency race conditions (e.g., simultaneous level
/// completions on multiple devices).
abstract class GamificationRepository {
  /// Records a game-level completion, updating XP, coins, completed levels,
  /// unlocked levels, daily XP history, and the recent-activity feed atomically.
  ///
  /// - Applies a 50 % XP reduction for replayed levels.
  /// - Respects permanent XP boost and active Double-XP power-up multipliers.
  /// - Routes coin rewards to [kidsCoins] for Kids Zone game types.
  /// - Doubles coin rewards for premium users or users at level ≥ 100.
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
    bool isVaultReward = false,
    int? starsEarned,
    int? addMagicStars,
    int? claimChestTier,
  });

  /// Advances the unlocked level for [categoryId] to [newLevel] if [newLevel]
  /// exceeds the currently stored value (monotonically increasing only).
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  );

  /// Adjusts [categoryStats] for [categoryId] by ±[kCategoryStatStep] based on
  /// [isCorrect], clamped to [[kCategoryStatMin], [kCategoryStatMax]].
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  );

  /// Appends [badgeId] to the user's earned badges list (idempotent via
  /// Firestore [FieldValue.arrayUnion]).
  Future<Either<Failure, void>> awardBadge(String badgeId);

  /// Deducts [cost] from the user's coin balance and increments [currentStreak]
  /// to repair a broken streak.
  Future<Either<Failure, void>> repairStreak(int cost);

  /// Deducts [cost] coins and grants one streak-freeze buffer item.
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost);

  /// Deducts [cost] coins and activates the 2× XP power-up for 24 hours.
  Future<Either<Failure, void>> activateDoubleXP(int cost);

  /// Deducts [cost] coins and explicitly increments the unlocked level
  /// for the specified [gameType]. Used for Toll Gate monetization.
  Future<Either<Failure, void>> purchaseLevelUnlock({
    required String gameType,
    required int cost,
    bool isKidsMode = false,
  });

  Future<Either<Failure, void>> purchaseGoldenKey({
    required int cost,
    required bool isKidsMode,
  });

  Future<Either<Failure, void>> addGoldenKey({
    required int amount,
  });
}
