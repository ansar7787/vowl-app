import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class ForgotPassword implements UseCase<void, String> {
  final AuthRepository repository;

  ForgotPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) async {
    return await repository.sendPasswordResetEmail(email);
  }
}
