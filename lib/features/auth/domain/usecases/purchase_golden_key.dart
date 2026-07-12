import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class PurchaseGoldenKeyParams extends Equatable {
  final int cost;
  final bool isKidsMode;

  const PurchaseGoldenKeyParams({required this.cost, required this.isKidsMode});

  @override
  List<Object?> get props => [cost, isKidsMode];
}

class PurchaseGoldenKey implements UseCase<void, PurchaseGoldenKeyParams> {
  final GamificationRepository repository;

  PurchaseGoldenKey(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseGoldenKeyParams params) async {
    return await repository.purchaseGoldenKey(
      cost: params.cost,
      isKidsMode: params.isKidsMode,
    );
  }
}
