import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class ActivateDoubleXP extends UseCase<void, int> {
  final GamificationRepository repository;

  ActivateDoubleXP(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) async {
    return await repository.activateDoubleXP(cost);
  }
}
