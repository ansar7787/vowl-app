import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateUser extends UseCase<void, UpdateUserParams> {
  final AuthRepository repository;

  UpdateUser(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserParams params) async {
    return await repository.updateUser(params.user);
  }
}

class UpdateUserParams {
  final UserEntity user;

  const UpdateUserParams({required this.user});
}
