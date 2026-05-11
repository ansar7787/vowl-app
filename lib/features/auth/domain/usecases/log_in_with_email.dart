import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class LogInWithEmail implements UseCase<UserEntity, LogInParams> {
  final AuthRepository repository;

  LogInWithEmail(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LogInParams params) async {
    return await repository.logInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class LogInParams extends Equatable {
  final String email;
  final String password;

  const LogInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
