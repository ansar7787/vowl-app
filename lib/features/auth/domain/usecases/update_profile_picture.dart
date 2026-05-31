import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

class UpdateProfilePicture extends UseCase<String, String> {
  final UserRepository repository;

  UpdateProfilePicture(this.repository);

  @override
  Future<Either<Failure, String>> call(String params) async {
    return await repository.updateProfilePicture(params);
  }
}
