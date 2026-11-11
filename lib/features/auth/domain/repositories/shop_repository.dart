import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

/// Domain contract for virtual currency, daily rewards, hint packs, and item management.
abstract class ShopRepository {
  /// Adjusts the user's [coins] balance by [amountChange] (positive = earn,
  /// negative = spend). When [title] is supplied, appends a corresponding
  /// entry to [coinHistory]. Rejects a spend that would overdraw the balance.
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  });

  /// Claims the standard daily gift reward. Enforces a once-per-calendar-day
  /// limit via a Firestore transaction guard on [lastDailyRewardDate].
  Future<Either<Failure, void>> claimDailyGift();

  /// Claims the daily chest reward of [amount] coins. Enforces a
  /// once-per-calendar-day limit, mutually exclusive with [claimDailyGift].
  Future<Either<Failure, void>> claimDailyChest(int amount);

  /// Decrements [hintCount] by one. Returns a [Failure] if no hints
  /// remain rather than allowing the count to go negative.
  Future<Either<Failure, void>> useHint();

  /// Deducts [cost] coins and increments [hintCount] by [hintAmount].
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount);

  /// Deducts [cost] from [coins] (only if [mascotId] isn't already owned)
  /// and equips it as [vowlMascot], adding it to [vowlOwnedMascots] if new.
  /// Re-equipping an already-owned mascot is always free. Runs atomically
  /// inside a Firestore transaction.
  Future<Either<Failure, void>> buyVowlMascot({
    required String mascotId,
    required int cost,
  });

  /// Deducts [cost] from [coins] (only if [accessoryId] isn't already owned)
  /// and equips it as [vowlEquippedAccessory], adding it to
  /// [vowlOwnedAccessories] if new. Re-equipping an already-owned accessory
  /// is always free. Runs atomically inside a Firestore transaction.
  Future<Either<Failure, void>> buyVowlAccessory({
    required String accessoryId,
    required int cost,
  });
}
