import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Exposes the continuous, real-time stream of the authenticated
/// [UserEntity], emitting `null` whenever no user is signed in.
///
/// Unlike every other use case in this feature, this deliberately does
/// **not** extend `UseCase<Type, Params>`: that base type models a one-shot
/// `Future<Either<Failure, Type>>` call, but this exposes a long-lived
/// [Stream] instead, which already has its own error channel — wrapping each
/// emission in `Either` would add nothing. BLoCs should subscribe to this
/// once (e.g. in their constructor) rather than calling it repeatedly.
class GetUserStream {
  final AuthRepository repository;

  const GetUserStream(this.repository);

  Stream<UserEntity?> call() {
    return repository.user;
  }
}
