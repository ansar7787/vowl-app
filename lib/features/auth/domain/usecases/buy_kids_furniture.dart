import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Parameters for [BuyKidsFurniture].
class BuyKidsFurnitureParams extends Equatable {
  final String category;
  final String furnitureId;
  final int cost;

  const BuyKidsFurnitureParams({
    required this.category,
    required this.furnitureId,
    required this.cost,
  });

  @override
  List<Object?> get props => [category, furnitureId, cost];
}

/// Purchases (or re-equips, if already owned) a Kids Zone furniture item,
/// deducting [BuyKidsFurnitureParams.cost] from `kidsCoins` only on a new
/// purchase.
///
/// Returns [AuthFailure('insufficient-kids-coins')] when the balance is
/// insufficient for a new purchase. Runs atomically inside a Firestore
/// transaction — see [ShopRepository.buyKidsFurniture] for why this
/// replaced a client-side implementation in `ProfileBloc`.
class BuyKidsFurniture extends UseCase<void, BuyKidsFurnitureParams> {
  final ShopRepository repository;

  const BuyKidsFurniture(this.repository);

  @override
  Future<Either<Failure, void>> call(BuyKidsFurnitureParams params) {
    return repository.buyKidsFurniture(
      category: params.category,
      furnitureId: params.furnitureId,
      cost: params.cost,
    );
  }
}
