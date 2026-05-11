import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class PurchaseHint implements UseCase<void, PurchaseHintParams> {
  final AuthRepository repository;

  PurchaseHint(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseHintParams params) async {
    return await repository.purchaseHint(params.cost, params.hintAmount);
  }
}

class PurchaseHintParams {
  final int cost;
  final int hintAmount;

  PurchaseHintParams({required this.cost, required this.hintAmount});
}
