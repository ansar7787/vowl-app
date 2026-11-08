import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Atomically claims the XP and coin bounty for an unlocked achievement badge.
class ClaimBadgeReward extends UseCase<void, String> {
  final GamificationRepository repository;

  ClaimBadgeReward(this.repository);

  @override
  Future<Either<Failure, void>> call(String badgeId) =>
      repository.claimBadgeReward(badgeId);
}

