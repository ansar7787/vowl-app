import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Appends [badgeId] to the authenticated user's earned badges list.
///
/// The write is idempotent — awarding a badge the user already holds
/// produces no change (backed by Firestore [FieldValue.arrayUnion]).
class AwardBadge extends UseCase<void, String> {
  final GamificationRepository repository;

  AwardBadge(this.repository);

  @override
  Future<Either<Failure, void>> call(String badgeId) =>
      repository.awardBadge(badgeId);
}
