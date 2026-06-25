import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Forces a reload of the Firebase Auth user record from the server.
///
/// Call this immediately after the user completes an email-verification link
/// so that [UserEntity.isEmailVerified] is updated from [false] to [true]
/// without waiting for the next auth state change event. The updated value
/// is then broadcast via [GetUserStream].
class ReloadUser extends UseCase<void, NoParams> {
  final AuthRepository repository;

  const ReloadUser(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.reloadUser();
}
