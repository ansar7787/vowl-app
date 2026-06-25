import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Purchases a Kids Zone accessory, deducting [BuyKidsAccessoryParams.cost]
/// from [kidsCoins] and adding [BuyKidsAccessoryParams.accessoryId] to the
/// owned accessories list.
///
/// Silently succeeds if the accessory is already owned (idempotent).
class BuyKidsAccessory extends UseCase<void, BuyKidsAccessoryParams> {
  final ShopRepository repository;

  BuyKidsAccessory(this.repository);

  @override
  Future<Either<Failure, void>> call(BuyKidsAccessoryParams params) =>
      repository.buyKidsAccessory(params.accessoryId, params.cost);
}

/// Parameters for [BuyKidsAccessory].
class BuyKidsAccessoryParams {
  final String accessoryId;
  final int cost;

  const BuyKidsAccessoryParams({required this.accessoryId, required this.cost});
}
