import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

class UpdateDisplayName extends UseCase<void, String> {
  final UserRepository repository;

  UpdateDisplayName(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.updateDisplayName(params);
  }
}
