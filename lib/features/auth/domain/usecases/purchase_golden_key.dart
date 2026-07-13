import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for [PurchaseGoldenKey].
class PurchaseGoldenKeyParams extends Equatable {
  final int cost;
  final bool isKidsMode;

  const PurchaseGoldenKeyParams({required this.cost, required this.isKidsMode});

  @override
  List<Object?> get props => [cost, isKidsMode];
}

/// Purchases one Golden Key, deducting [PurchaseGoldenKeyParams.cost] from
/// `kidsCoins` (when [PurchaseGoldenKeyParams.isKidsMode] is `true`) or
/// `coins` (otherwise). Golden Keys themselves are a single universal
/// balance — not split by mode — so exactly one key is credited either way.
///
/// Returns [AuthFailure('insufficient-kids-coins')] or
/// [AuthFailure('insufficient-coins')] (depending on
/// [PurchaseGoldenKeyParams.isKidsMode]) when the balance is insufficient.
/// Runs atomically inside a Firestore transaction.
class PurchaseGoldenKey extends UseCase<void, PurchaseGoldenKeyParams> {
  final GamificationRepository repository;

  const PurchaseGoldenKey(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseGoldenKeyParams params) async {
    return await repository.purchaseGoldenKey(
      cost: params.cost,
      isKidsMode: params.isKidsMode,
    );
  }
}
