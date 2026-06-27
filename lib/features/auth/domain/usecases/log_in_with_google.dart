import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Initiates a Google Sign-In OAuth flow.
///
/// On success the Firebase Auth session is established. The authenticated
/// [UserEntity] (including the provisioned Firestore document for first-time
/// Google users) is delivered via [GetUserStream] rather than this call's
/// return value, which only confirms the flow completed without error.
///
/// Returns [AuthFailure('aborted-by-user')] when the user dismisses the
/// Google account picker without selecting an account.
class LogInWithGoogle extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  const LogInWithGoogle(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      repository.logInWithGoogle();
}
