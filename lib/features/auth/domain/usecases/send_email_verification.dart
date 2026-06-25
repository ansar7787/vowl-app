import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Sends an email-verification link to the currently authenticated user's
/// email address.
///
/// Firebase rate-limits this call to prevent abuse; repeated invocations may
/// return [AuthFailure('too-many-requests')]. After the user clicks the link,
/// call [ReloadUser] to refresh [UserEntity.isEmailVerified] immediately.
class SendEmailVerification extends UseCase<void, NoParams> {
  final AuthRepository repository;

  const SendEmailVerification(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.sendEmailVerification();
}
