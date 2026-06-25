import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Fetches the currently authenticated [UserEntity] from Firestore, or returns
/// [null] when no user is signed in.
///
/// Uses the Firestore default source (server-and-cache) so this succeeds
/// offline when data is locally cached. The persistent [GetUserStream] remains
/// authoritative for real-time updates; use this only for one-shot reads
/// (e.g., determining auth state on cold app launch).
class GetCurrentUser extends UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  const GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      repository.getCurrentUser();
}
