import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

abstract class GamificationRepository {
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
  });
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  );
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  );
  Future<void> awardBadge(String badgeId);
  Future<Either<Failure, void>> repairStreak(int cost);
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost);
  Future<Either<Failure, void>> activateDoubleXP(int cost);
}
