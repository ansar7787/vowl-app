import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateKidsMascot implements UseCase<void, String> {
  final AuthRepository repository;

  UpdateKidsMascot(this.repository);

  @override
  Future<Either<Failure, void>> call(String mascotId) async {
    return await repository.updateKidsMascot(mascotId);
  }
}
