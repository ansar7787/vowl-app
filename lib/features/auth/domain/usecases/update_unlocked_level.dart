import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Advances the highest unlocked level for [UpdateUnlockedLevelParams.categoryId]
/// to [UpdateUnlockedLevelParams.newLevel].
///
/// The update is monotonically increasing — if [newLevel] is less than or equal
/// to the currently stored value it is silently ignored, preventing level
/// regressions from race conditions or out-of-order network responses.
class UpdateUnlockedLevel extends UseCase<void, UpdateUnlockedLevelParams> {
  final GamificationRepository repository;

  const UpdateUnlockedLevel(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUnlockedLevelParams params) =>
      repository.updateUnlockedLevel(params.categoryId, params.newLevel);
}

/// Immutable value object carrying the level-unlock fields for
/// [UpdateUnlockedLevel].
@immutable
class UpdateUnlockedLevelParams extends Equatable {
  final String categoryId;
  final int newLevel;

  const UpdateUnlockedLevelParams({
    required this.categoryId,
    required this.newLevel,
  });

  @override
  List<Object?> get props => [categoryId, newLevel];
}
