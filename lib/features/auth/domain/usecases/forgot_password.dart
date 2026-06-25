import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Dispatches a password-reset email to the supplied [email] address via
/// Firebase Auth.
///
/// Succeeds even when no account exists for [email] (Firebase intentionally
/// does not reveal whether an address is registered). The presentation layer
/// should always show a "check your inbox" confirmation regardless of the
/// result to avoid account-enumeration attacks.
class ForgotPassword extends UseCase<void, String> {
  final AuthRepository repository;

  const ForgotPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) =>
      repository.sendPasswordResetEmail(email);
}
