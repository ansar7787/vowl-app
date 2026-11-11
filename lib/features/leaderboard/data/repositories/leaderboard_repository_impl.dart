import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Concrete implementation of [LeaderboardRepository] querying Firestore
/// cached leaderboards with client-side timeout guards and fallback queries.
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final FirebaseFirestore firestore;

  // FIX (CRITICAL-4): Added client-side timeout to prevent indefinite hangs
  // on poor networks. Firestore has no built-in client timeout by default.
  static const Duration _kNetworkTimeout = Duration(seconds: 10);

  LeaderboardRepositoryImpl(this.firestore);

  @override
  Future<Either<Failure, LeaderboardResult>> getTopUsers({
    int limit = 50,
  }) async {
    try {
      final cacheDocRef = firestore
          .collection('metadata')
          .doc('leaderboard_cache');

      // FIX (CRITICAL-4): .timeout() ensures we fail fast and emit an error
      // state instead of hanging forever on poor/no connectivity.
      final cacheSnapshot = await cacheDocRef.get().timeout(_kNetworkTimeout);

      if (cacheSnapshot.exists && cacheSnapshot.data() != null) {
        // PRODUCTION LOGIC: Always return the cache if it exists.
        // The backend Firebase Cloud Function is 100% responsible for
        // refreshing this document — eliminating the cache-stampede problem.
        final data = cacheSnapshot.data()!;
        final lastUpdated =
            (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();

        final List<dynamic> usersJson = data['users'] ?? [];
        final users = usersJson
            .map(
              (json) =>
                  UserModel.fromMap(Map<String, dynamic>.from(json as Map)),
            )
            .toList();

        return Right(LeaderboardResult(users: users, lastUpdated: lastUpdated));
      }

      // ======================================================================
      // ONE-TIME FALLBACK: Only runs before the Cloud Function fires for the
      // very first time (cold-start / empty metadata collection).
      // ======================================================================
      final snapshot = await firestore
          .collection('users')
          .orderBy('currentWeeklyExp', descending: true)
          .limit(limit)
          .get()
          .timeout(_kNetworkTimeout);

      final List<Map<String, dynamic>> usersData = [];
      final List<UserEntity> users = [];
      final fetchTime = DateTime.now();

      for (final doc in snapshot.docs) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = (data['id'] as String?) ?? doc.id;
          final user = UserModel.fromMap(data);
          users.add(user);
          usersData.add({
            'id': data['id'],
            'displayName': user.safeDisplayName,
            'photoUrl': data['photoUrl'],
            'totalExp': data['totalExp'],
            'currentStreak': data['currentStreak'],
            'completedLevels': data['completedLevels'],
            'isPremium': data['isPremium'] ?? false,
            'previousRank': data['previousRank'] ?? users.length,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('LeaderboardRepo: Corrupted user doc: $e');
        }
      }

      // NOTE: Cache seeding removed — security rules block client writes to
      // the metadata collection (allow write: if false). The Cloud Function
      // handles cache population. The previous client-side write was dead code
      // that always failed silently.

      return Right(LeaderboardResult(users: users, lastUpdated: fetchTime));
    } on TimeoutException {
      return const Left(
        ServerFailure('Connection timed out. Please check your network.'),
      );
    } catch (e) {
      // FIX (SECURITY): Do not surface raw exception toString() to the user.
      // Log the detail in debug mode only; emit a generic message to the UI.
      if (kDebugMode) debugPrint('LeaderboardRepo: Unexpected error: $e');
      return const Left(
        ServerFailure('Unable to load leaderboard. Please try again.'),
      );
    }
  }
}
