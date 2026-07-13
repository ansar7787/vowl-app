import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Parameters for [BuyVowlAccessory].
class BuyVowlAccessoryParams extends Equatable {
  final String accessoryId;
  final int cost;

  const BuyVowlAccessoryParams({required this.accessoryId, required this.cost});

  @override
  List<Object?> get props => [accessoryId, cost];
}

/// Purchases (or re-equips, if already owned) a Vowl accessory, deducting
/// [BuyVowlAccessoryParams.cost] from `coins` only on a new purchase.
///
/// Returns [AuthFailure('insufficient-coins')] when the balance is
/// insufficient for a new purchase. Runs atomically inside a Firestore
/// transaction — see [ShopRepository.buyVowlAccessory] for why this
/// replaced a client-side implementation in `ProfileBloc`.
class BuyVowlAccessory extends UseCase<void, BuyVowlAccessoryParams> {
  final ShopRepository repository;

  const BuyVowlAccessory(this.repository);

  @override
  Future<Either<Failure, void>> call(BuyVowlAccessoryParams params) {
    return repository.buyVowlAccessory(
      accessoryId: params.accessoryId,
      cost: params.cost,
    );
  }
}
