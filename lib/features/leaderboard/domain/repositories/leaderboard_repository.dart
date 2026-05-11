import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class LeaderboardResult {
  final List<UserEntity> users;
  final DateTime lastUpdated;

  const LeaderboardResult({required this.users, required this.lastUpdated});
}

abstract class LeaderboardRepository {
  Future<Either<Failure, LeaderboardResult>> getTopUsers({int limit = 10});
}
