import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UseHint extends UseCase<void, NoParams> {
  final AuthRepository repository;

  UseHint(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.useHint();
  }
}
