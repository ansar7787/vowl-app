import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateDisplayName extends UseCase<void, String> {
  final AuthRepository repository;

  UpdateDisplayName(this.repository);

  @override
  Future<Either<Failure, void>> call(String displayName) async {
    return await repository.updateDisplayName(displayName);
  }
}
