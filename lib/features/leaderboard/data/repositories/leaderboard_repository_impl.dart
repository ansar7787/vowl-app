import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';

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
          .orderBy('totalExp', descending: true)
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
          users.add(UserModel.fromMap(data));
          usersData.add({
            'id': data['id'],
            'displayName': data['displayName'],
            'photoUrl': data['photoUrl'],
            'totalExp': data['totalExp'],
            'currentStreak': data['currentStreak'],
            'completedLevels': data['completedLevels'],
            'isPremium': data['isPremium'] ?? false,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('LeaderboardRepo: Corrupted user doc: $e');
        }
      }

      // Seed the cache so future reads are O(1) single-document fetches.
      // Wrapped in try-catch because clients may lack write permissions on
      // the metadata collection in stricter Firestore security rule configs.
      try {
        await cacheDocRef
            .set({
              'lastUpdated': FieldValue.serverTimestamp(),
              'users': usersData,
            }, SetOptions(merge: true))
            .timeout(_kNetworkTimeout);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LeaderboardRepo: Failed to seed metadata cache: $e');
        }
      }

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

  @override
  Future<Either<Failure, LeaderboardResult>> getTopKidsUsers({
    int limit = 50,
  }) async {
    try {
      final cacheDocRef = firestore
          .collection('metadata')
          .doc('kids_leaderboard_cache');

      DocumentSnapshot<Map<String, dynamic>>? cacheSnapshot;
      try {
        cacheSnapshot = await cacheDocRef.get().timeout(_kNetworkTimeout);
      } catch (e) {
        if (kDebugMode) debugPrint('LeaderboardRepo: Failed to read kids cache: $e');
      }

      if (cacheSnapshot != null && cacheSnapshot.exists && cacheSnapshot.data() != null) {
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

      final snapshot = await firestore
          .collection('users')
          .orderBy('kidsCoins', descending: true)
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
          users.add(UserModel.fromMap(data));
          
          usersData.add({
            'id': data['id'],
            'displayName': data['displayName'],
            'photoUrl': data['photoUrl'],
            'kidsCoins': data['kidsCoins'] ?? 0,
            'currentStreak': data['currentStreak'],
            'completedLevels': data['completedLevels'],
            'isPremium': data['isPremium'] ?? false,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('LeaderboardRepo: Corrupted user doc: $e');
        }
      }

      try {
        await cacheDocRef
            .set({
              'lastUpdated': FieldValue.serverTimestamp(),
              'users': usersData,
            }, SetOptions(merge: true))
            .timeout(_kNetworkTimeout);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LeaderboardRepo: Failed to seed metadata cache: $e');
        }
      }

      return Right(LeaderboardResult(users: users, lastUpdated: fetchTime));
    } on TimeoutException {
      return const Left(
        ServerFailure('Connection timed out. Please check your network.'),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('LeaderboardRepo: Unexpected error: $e');
      return const Left(
        ServerFailure('Unable to load kids leaderboard. Please try again.'),
      );
    }
  }
}
