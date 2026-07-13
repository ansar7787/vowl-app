import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Parameters for [BuyVowlMascot].
class BuyVowlMascotParams extends Equatable {
  final String mascotId;
  final int cost;

  const BuyVowlMascotParams({required this.mascotId, required this.cost});

  @override
  List<Object?> get props => [mascotId, cost];
}

/// Purchases (or re-equips, if already owned) a Vowl mascot, deducting
/// [BuyVowlMascotParams.cost] from `coins` only on a new purchase.
///
/// Returns [AuthFailure('insufficient-coins')] when the balance is
/// insufficient for a new purchase. Runs atomically inside a Firestore
/// transaction — see [ShopRepository.buyVowlMascot] for why this replaced a
/// client-side implementation in `ProfileBloc`.
class BuyVowlMascot extends UseCase<void, BuyVowlMascotParams> {
  final ShopRepository repository;

  const BuyVowlMascot(this.repository);

  @override
  Future<Either<Failure, void>> call(BuyVowlMascotParams params) {
    return repository.buyVowlMascot(
      mascotId: params.mascotId,
      cost: params.cost,
    );
  }
}
