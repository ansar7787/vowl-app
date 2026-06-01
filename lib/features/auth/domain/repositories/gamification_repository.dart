import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

/// Abstract domain contract defining the Gamification progress and achievements repository.
///
/// Ensures strict Clean Architecture principles using Functional Programming Either failures.
abstract class GamificationRepository {
  /// Upgrades daily levels progress, user exp, and coin multipliers after a game completion.
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
  });

  /// Increments category levels unlock progressions for user entities.
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  );

  /// Computes category correctness levels metrics inside player profiles.
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  );

  /// Grants a newly earned milestone achievement badge to the player safely.
  Future<Either<Failure, void>> awardBadge(String badgeId);

  /// Repairs broken streaks using game currency (coins).
  Future<Either<Failure, void>> repairStreak(int cost);

  /// Purchases a streak freeze buffer.
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost);

  /// Activates 2x XP boost multipliers.
  Future<Either<Failure, void>> activateDoubleXP(int cost);
}
