import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';

/// Domain contract for virtual currency, daily rewards, hint packs, and Kids
/// Zone item management.
abstract class ShopRepository {
  /// Adjusts the user's [coins] balance by [amountChange] (positive = earn,
  /// negative = spend). When [title] is supplied, appends a corresponding
  /// entry to [coinHistory]. Rejects a spend that would overdraw the balance.
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  });

  /// Increments [kidsCoins] by [amount].
  Future<Either<Failure, void>> awardKidsCoins(int amount);

  /// Claims the standard daily gift reward. Enforces a once-per-calendar-day
  /// limit via a Firestore transaction guard on [lastDailyRewardDate].
  Future<Either<Failure, void>> claimDailyGift();

  /// Claims the daily chest reward of [amount] coins. Enforces a
  /// once-per-calendar-day limit, mutually exclusive with [claimDailyGift].
  Future<Either<Failure, void>> claimDailyChest(int amount);

  /// Claims the Kids Zone daily reward of [amount] kids-coins. Enforces a
  /// once-per-calendar-day limit via [lastKidsDailyRewardDate].
  Future<Either<Failure, void>> claimKidsDailyReward(int amount);

  /// Decrements [hintCount] by one. Returns a [Failure] if no hints
  /// remain rather than allowing the count to go negative.
  Future<Either<Failure, void>> useHint();

  /// Deducts [cost] coins and increments [hintCount] by [hintAmount].
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount);

  /// Appends [stickerId] to [kidsStickers] (idempotent via arrayUnion).
  Future<Either<Failure, void>> awardKidsSticker(String stickerId);

  /// Sets [kidsMascot] to [mascotId].
  Future<Either<Failure, void>> updateKidsMascot(String mascotId);

  /// Deducts [cost] from [kidsCoins] and appends [accessoryId] to
  /// [kidsOwnedAccessories]. Silently succeeds if the item is already owned.
  Future<Either<Failure, void>> buyKidsAccessory(String accessoryId, int cost);

  /// Sets [kidsEquippedAccessory] to [accessoryId] (or null to unequip).
  Future<Either<Failure, void>> equipKidsAccessory(String? accessoryId);

  /// Deducts [cost] from [kidsCoins] (only if [furnitureId] isn't already
  /// owned) and sets `kidsEquippedFurniture[category]` to [furnitureId],
  /// adding it to [kidsOwnedFurniture] if new. Re-equipping an already-owned
  /// item is always free. Runs atomically inside a Firestore transaction.
  ///
  /// Added to close a client-side read-then-write purchase in the
  /// presentation layer (`ProfileBloc._onBuyFurniture`, previously
  /// implemented via a full-document [updateUserCoins]-less `updateUser`
  /// write with no transaction) that could let a concurrent purchase on a
  /// second device drive the balance negative.
  Future<Either<Failure, void>> buyKidsFurniture({
    required String category,
    required String furnitureId,
    required int cost,
  });

  /// Deducts [cost] from [coins] (only if [mascotId] isn't already owned)
  /// and equips it as [vowlMascot], adding it to [vowlOwnedMascots] if new.
  /// Re-equipping an already-owned mascot is always free. Runs atomically
  /// inside a Firestore transaction.
  ///
  /// Added for the same reason as [buyKidsFurniture] — replaces a client-side
  /// read-then-write purchase in `ProfileBloc._onBuyVowlMascot`.
  Future<Either<Failure, void>> buyVowlMascot({
    required String mascotId,
    required int cost,
  });

  /// Deducts [cost] from [coins] (only if [accessoryId] isn't already owned)
  /// and equips it as [vowlEquippedAccessory], adding it to
  /// [vowlOwnedAccessories] if new. Re-equipping an already-owned accessory
  /// is always free. Runs atomically inside a Firestore transaction.
  ///
  /// Added for the same reason as [buyKidsFurniture] — replaces a client-side
  /// read-then-write purchase in `ProfileBloc._onBuyVowlAccessory`.
  Future<Either<Failure, void>> buyVowlAccessory({
    required String accessoryId,
    required int cost,
  });
}
