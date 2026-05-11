import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfilePicture extends UseCase<String, String> {
  final AuthRepository repository;

  UpdateProfilePicture(this.repository);

  @override
  Future<Either<Failure, String>> call(String filePath) async {
    return await repository.updateProfilePicture(filePath);
  }
}
