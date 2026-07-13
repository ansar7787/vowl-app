import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Claims the coin reward for reaching a [milestone]-day streak.
///
/// Deliberately takes only the milestone, not a reward amount — the reward
/// is looked up server-side from `UserGameConstants.kStreakMilestoneRewards`
/// and the claim is rejected if it was already recorded. This replaces
/// `ProgressionBloc._onClaimStreakMilestone`'s previous implementation,
/// which accepted a `reward` value directly from the triggering event with
/// no check that the milestone hadn't already been paid out — closing a
/// duplicate-claim / arbitrary-reward vulnerability.
///
/// Returns [AuthFailure('unrecognized-milestone')] if [milestone] isn't in
/// the reward table, or [AuthFailure('milestone-already-claimed')] if it was
/// already claimed. Runs atomically inside a Firestore transaction.
class ClaimStreakMilestone extends UseCase<void, int> {
  final GamificationRepository repository;

  const ClaimStreakMilestone(this.repository);

  @override
  Future<Either<Failure, void>> call(int milestone) =>
      repository.claimStreakMilestone(milestone: milestone);
}
