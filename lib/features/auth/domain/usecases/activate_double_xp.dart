import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Deducts [cost] coins and activates the 2× XP power-up for 24 hours.
class ActivateDoubleXP extends UseCase<void, int> {
  final GamificationRepository repository;

  ActivateDoubleXP(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) =>
      repository.activateDoubleXP(cost);
}
