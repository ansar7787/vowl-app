import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Deducts [cost] coins and repairs a broken streak, restoring it to at least
/// 2 days (or incrementing it by 1 if it was already greater than 1).
///
/// Returns [AuthFailure('insufficient-coins')] when the balance is
/// insufficient. Runs atomically inside a Firestore transaction to prevent
/// concurrent balance exploits.
class RepairStreak extends UseCase<void, int> {
  final GamificationRepository repository;

  const RepairStreak(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) => repository.repairStreak(cost);
}
