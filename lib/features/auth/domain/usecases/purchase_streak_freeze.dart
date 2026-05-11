import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class PurchaseStreakFreeze extends UseCase<void, int> {
  final AuthRepository repository;

  PurchaseStreakFreeze(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) async {
    return await repository.purchaseStreakFreeze(cost);
  }
}
