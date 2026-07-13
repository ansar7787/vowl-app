import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for [ClaimLevelMilestone].
class ClaimLevelMilestoneParams extends Equatable {
  final int milestone;
  final int reward;

  const ClaimLevelMilestoneParams({
    required this.milestone,
    required this.reward,
  });

  @override
  List<Object?> get props => [milestone, reward];
}

/// Claims the coin reward for reaching a level [ClaimLevelMilestoneParams.milestone].
///
/// See [GamificationRepository.claimLevelMilestone]'s doc comment for an
/// important caveat: unlike [ClaimStreakMilestone], there is currently no
/// server-side level-milestone reward table in this feature slice, so
/// [ClaimLevelMilestoneParams.reward] is still trusted from the caller. What
/// *is* closed: duplicate claims (rejected if already recorded) and claims
/// for a level the user hasn't actually reached (checked server-side against
/// `totalExp`, not a caller-supplied level).
///
/// Returns [AuthFailure('milestone-already-claimed')] or
/// [AuthFailure('milestone-not-yet-reached')] accordingly. Runs atomically
/// inside a Firestore transaction.
class ClaimLevelMilestone extends UseCase<void, ClaimLevelMilestoneParams> {
  final GamificationRepository repository;

  const ClaimLevelMilestone(this.repository);

  @override
  Future<Either<Failure, void>> call(ClaimLevelMilestoneParams params) {
    return repository.claimLevelMilestone(
      milestone: params.milestone,
      reward: params.reward,
    );
  }
}
