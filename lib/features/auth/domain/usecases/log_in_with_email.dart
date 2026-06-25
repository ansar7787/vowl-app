import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Signs the user in with their email address and password.
///
/// On success returns the full [UserEntity] fetched from Firestore, including
/// coins, XP, streak, and all profile fields. The persistent [GetUserStream]
/// remains authoritative for real-time updates after sign-in.
///
/// Common [AuthFailure] codes returned on the [Left] branch:
/// - `'user-not-found'` — no account for this email.
/// - `'wrong-password'` — incorrect password.
/// - `'user-disabled'` — account has been disabled.
/// - `'too-many-requests'` — rate-limited by Firebase.
class LogInWithEmail extends UseCase<UserEntity, LogInParams> {
  final AuthRepository repository;

  const LogInWithEmail(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LogInParams params) =>
      repository.logInWithEmail(email: params.email, password: params.password);
}

/// Immutable value object carrying the credentials for [LogInWithEmail].
@immutable
class LogInParams extends Equatable {
  final String email;
  final String password;

  const LogInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
