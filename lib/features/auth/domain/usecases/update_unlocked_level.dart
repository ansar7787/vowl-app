import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateUnlockedLevel extends UseCase<void, UpdateUnlockedLevelParams> {
  final AuthRepository repository;

  UpdateUnlockedLevel(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUnlockedLevelParams params) async {
    return await repository.updateUnlockedLevel(
      params.categoryId,
      params.newLevel,
    );
  }
}

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
