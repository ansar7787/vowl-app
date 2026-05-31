import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get user;
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserEntity>> logInWithEmail({
    required String email,
    required String password,
  });
  Future<Either<Failure, void>> logInWithGoogle();
  Future<Either<Failure, void>> logOut();
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, void>> reloadUser();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> deleteAccount();
}
