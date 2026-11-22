import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/domain/utils/weekly_league_reward_helper.dart';

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

        final List<dynamic> winnersJson = data['lastWeekWinners'] ?? [];
        List<Map<String, dynamic>> lastWeekWinners = winnersJson
            .map(
              (json) => Map<String, dynamic>.from(json as Map),
            )
            .toList();

        // Resilient fetch: If cache document does not have lastWeekWinners,
        // attempt to fetch the verified weekly winners directly from the users collection.
        if (lastWeekWinners.isEmpty) {
          try {
            final prevWeekKey = WeeklyLeagueRewardHelper.getPreviousWeekKey();
            final winnersSnap = await firestore
                .collection('users')
                .where('previousRankWeekKey', isEqualTo: prevWeekKey)
                .where('previousRank', isLessThanOrEqualTo: 10)
                .orderBy('previousRank')
                .get()
                .timeout(const Duration(seconds: 4));

            if (winnersSnap.docs.isNotEmpty) {
              lastWeekWinners = winnersSnap.docs.map((doc) {
                final d = doc.data();
                return {
                  'id': doc.id,
                  'rank': (d['previousRank'] as num?)?.toInt() ?? 10,
                  'displayName': d['displayName'] ?? 'Vowl Learner',
                  'photoUrl': d['photoUrl'],
                  'weeklyXp': (d['weeklyXp'] as num?)?.toInt() ?? 0,
                  'currentStreak': (d['currentStreak'] as num?)?.toInt() ?? 0,
                  'weekKey': prevWeekKey,
                };
              }).toList();
            }
          } catch (_) {
            // Keep empty list if query unavailable
          }
        }

        return Right(
          LeaderboardResult(
            users: users,
            lastUpdated: lastUpdated,
            lastWeekWinners: lastWeekWinners,
          ),
        );
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
            'previousRank': data['previousRank'],
            'previousRankWeekKey': data['previousRankWeekKey'],
          });
        } catch (e) {
          if (kDebugMode) debugPrint('LeaderboardRepo: Corrupted user doc: $e');
        }
      }

      List<Map<String, dynamic>> fallbackWinners = [];
      try {
        final prevWeekKey = WeeklyLeagueRewardHelper.getPreviousWeekKey();
        final winnersSnap = await firestore
            .collection('users')
            .where('previousRankWeekKey', isEqualTo: prevWeekKey)
            .where('previousRank', isLessThanOrEqualTo: 10)
            .orderBy('previousRank')
            .get()
            .timeout(const Duration(seconds: 4));

        if (winnersSnap.docs.isNotEmpty) {
          fallbackWinners = winnersSnap.docs.map((doc) {
            final d = doc.data();
            return {
              'id': doc.id,
              'rank': (d['previousRank'] as num?)?.toInt() ?? 10,
              'displayName': d['displayName'] ?? 'Vowl Learner',
              'photoUrl': d['photoUrl'],
              'weeklyXp': (d['weeklyXp'] as num?)?.toInt() ?? 0,
              'currentStreak': (d['currentStreak'] as num?)?.toInt() ?? 0,
              'weekKey': prevWeekKey,
            };
          }).toList();
        }
      } catch (_) {}

      return Right(
        LeaderboardResult(
          users: users,
          lastUpdated: fetchTime,
          lastWeekWinners: fallbackWinners,
        ),
      );
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
