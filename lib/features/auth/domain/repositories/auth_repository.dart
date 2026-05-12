import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get user;
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserEntity>> logInWithEmail({
    required String email,
    required String password,
  });
  Future<Either<Failure, void>> logInWithGoogle();
  Future<Either<Failure, void>> logOut();
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  });
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
  });
  Future<Either<Failure, void>> useHint();
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount);
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  );
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  );
  Future<void> awardBadge(String badgeId);
  Future<Either<Failure, void>> reloadUser();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> updateUser(UserEntity user);
  Future<Either<Failure, void>> claimVipGift();
  Future<Either<Failure, String>> updateProfilePicture(String filePath);
  Future<Either<Failure, void>> updateDisplayName(String displayName);
  Future<Either<Failure, void>> awardKidsSticker(String stickerId);
  Future<Either<Failure, void>> updateKidsMascot(String mascotId);
  Future<Either<Failure, void>> buyKidsAccessory(String accessoryId, int cost);
  Future<Either<Failure, void>> equipKidsAccessory(String? accessoryId);
  Future<Either<Failure, void>> repairStreak(int cost);
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost);
  Future<Either<Failure, void>> activateDoubleXP(int cost);
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, void>> awardKidsCoins(int amount);
  Future<Either<Failure, void>> claimDailyGift();
  Future<Either<Failure, void>> claimDailyChest(int amount);
  Future<Either<Failure, void>> claimKidsDailyReward(int amount);
}
