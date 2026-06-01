import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class AwardBadge implements UseCase<void, String> {
  final GamificationRepository repository;

  AwardBadge(this.repository);

  @override
  Future<Either<Failure, void>> call(String badgeId) async {
    return repository.awardBadge(badgeId);
  }
}
