import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Adjusts [categoryId]'s mastery score by ±[kCategoryStatStep] based on
/// whether the user answered [UpdateCategoryStatsParams.isCorrect].
///
/// The score is clamped to [[kCategoryStatMin], [kCategoryStatMax]] (0–100)
/// and stored in [UserEntity.categoryStats]. Runs atomically inside a
/// Firestore transaction.
class UpdateCategoryStats extends UseCase<void, UpdateCategoryStatsParams> {
  final GamificationRepository repository;

  const UpdateCategoryStats(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCategoryStatsParams params) =>
      repository.updateCategoryStats(params.categoryId, params.isCorrect);
}

/// Immutable value object carrying the stat-update fields for
/// [UpdateCategoryStats].
@immutable
class UpdateCategoryStatsParams extends Equatable {
  final String categoryId;
  final bool isCorrect;

  const UpdateCategoryStatsParams({
    required this.categoryId,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [categoryId, isCorrect];
}
