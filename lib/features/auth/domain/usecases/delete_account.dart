import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Permanently deletes the authenticated user's account, Firestore document,
/// Firebase Storage assets, and local SharedPreferences data.
///
/// Returns [AuthFailure('requires-recent-login')] when Firebase requires the
/// user to re-authenticate before deletion can proceed; the presentation layer
/// should prompt re-authentication and retry.
class DeleteAccount extends UseCase<void, NoParams> {
  final AuthRepository repository;

  const DeleteAccount(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.deleteAccount();
}
