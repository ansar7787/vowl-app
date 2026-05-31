import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> updateUser(UserEntity user);
  Future<Either<Failure, void>> updateDisplayName(String displayName);
  Future<Either<Failure, String>> updateProfilePicture(String filePath);
  Future<Either<Failure, void>> claimVipGift();
}
