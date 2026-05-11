import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateCategoryStats implements UseCase<void, UpdateCategoryStatsParams> {
  final AuthRepository _repository;

  UpdateCategoryStats(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateCategoryStatsParams params) async {
    return await _repository.updateCategoryStats(
      params.categoryId,
      params.isCorrect,
    );
  }
}

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
