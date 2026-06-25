import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Signs the user out from Firebase Auth and clears any cached Google
/// provider session.
///
/// After a successful sign-out [GetUserStream] emits [null], which BLoCs
/// can use to navigate the user to the authentication screen.
///
/// The Google provider sign-out is best-effort; a [NetworkFailure] from that
/// step does not prevent the Firebase Auth session from being cleared.
class LogOut extends UseCase<void, NoParams> {
  final AuthRepository repository;

  const LogOut(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.logOut();
}
