import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Creates a new Firebase Auth account, sets the display name, and provisions
/// the initial Firestore user document.
///
/// On success returns the complete [UserEntity] with all default field values
/// (level 1, zero coins, default unlocked levels, etc.).
///
/// Common [AuthFailure] codes on the [Left] branch:
/// - `'email-already-in-use'` — an account for this address already exists.
/// - `'invalid-email'` — the email address is malformed.
/// - `'weak-password'` — the password does not meet Firebase's strength policy.
class SignUp extends UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  const SignUp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) =>
      repository.signUp(
        name: params.name,
        email: params.email,
        password: params.password,
      );
}

/// Immutable value object carrying the registration fields for [SignUp].
@immutable
class SignUpParams extends Equatable {
  final String name;
  final String email;
  final String password;

  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}
