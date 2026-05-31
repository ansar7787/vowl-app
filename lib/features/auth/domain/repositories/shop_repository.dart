import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

abstract class ShopRepository {
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  });
  Future<Either<Failure, void>> awardKidsCoins(int amount);
  Future<Either<Failure, void>> claimDailyGift();
  Future<Either<Failure, void>> claimDailyChest(int amount);
  Future<Either<Failure, void>> claimKidsDailyReward(int amount);
  Future<Either<Failure, void>> useHint();
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount);
  Future<Either<Failure, void>> awardKidsSticker(String stickerId);
  Future<Either<Failure, void>> updateKidsMascot(String mascotId);
  Future<Either<Failure, void>> buyKidsAccessory(String accessoryId, int cost);
  Future<Either<Failure, void>> equipKidsAccessory(String? accessoryId);
}
