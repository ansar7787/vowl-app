import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Encapsulates the result of a leaderboard fetch, including the cached
/// timestamp so the UI can display a human-readable "updated X ago" label.
class LeaderboardResult {
  final List<UserEntity> users;
  final DateTime lastUpdated;

  const LeaderboardResult({required this.users, required this.lastUpdated});
}

/// Contract that any leaderboard data source must fulfil.
/// Returning [Either<Failure, LeaderboardResult>] keeps error handling
/// explicit and prevents uncaught exceptions from reaching the BLoC layer.
abstract class LeaderboardRepository {
  Future<Either<Failure, LeaderboardResult>> getTopUsers({int limit = 50});
}
