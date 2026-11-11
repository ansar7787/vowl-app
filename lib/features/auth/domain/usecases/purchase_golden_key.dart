import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for [PurchaseGoldenKey].
class PurchaseGoldenKeyParams extends Equatable {
  final int cost;

  const PurchaseGoldenKeyParams({required this.cost});

  @override
  List<Object?> get props => [cost];
}

/// Purchases one Golden Key, deducting [PurchaseGoldenKeyParams.cost] from
/// `coins`. Runs atomically inside a Firestore transaction.
class PurchaseGoldenKey extends UseCase<void, PurchaseGoldenKeyParams> {
  final GamificationRepository repository;

  const PurchaseGoldenKey(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseGoldenKeyParams params) async {
    return await repository.purchaseGoldenKey(
      cost: params.cost,
    );
  }
}
