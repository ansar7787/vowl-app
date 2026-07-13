import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Repairs a broken streak with no coin cost (the "watch an ad instead"
/// variant of [RepairStreak]) — restores it to at least 2 days, or
/// increments it by 1 if it was already greater than 1.
///
/// Runs atomically inside a Firestore transaction, so the streak read stays
/// consistent even if this fires from two sessions at once. Replaces
/// `ProgressionBloc._onRepairStreakWithAd`'s previous client-side
/// implementation via a generic `UpdateUser` call.
class RepairStreakFree extends UseCase<void, NoParams> {
  final GamificationRepository repository;

  const RepairStreakFree(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.repairStreakFree();
}
