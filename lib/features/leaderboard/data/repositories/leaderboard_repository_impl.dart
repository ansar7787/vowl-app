import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final FirebaseFirestore firestore;

  LeaderboardRepositoryImpl(this.firestore);

  @override
  Future<Either<Failure, LeaderboardResult>> getTopUsers({int limit = 50}) async {
    try {
      final cacheDocRef = firestore.collection('metadata').doc('leaderboard_cache');
      
      final cacheSnapshot = await cacheDocRef.get();
      
      if (cacheSnapshot.exists && cacheSnapshot.data() != null) {
        // PRODUCTION LOGIC: Always return the cache if it exists.
        // We no longer check if it's 4 hours old on the client side.
        // The backend Firebase Cloud Function is now 100% responsible for updating this document.
        // This completely eliminates the "Cache Stampede / Thundering Herd" problem.
        final data = cacheSnapshot.data()!;
        final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        final List<dynamic> usersJson = data['users'] ?? [];
        final users = usersJson.map((json) => UserModel.fromMap(Map<String, dynamic>.from(json))).toList();
        return Right(LeaderboardResult(users: users, lastUpdated: lastUpdated));
      }

      // ======================================================================
      // ONE-TIME FALLBACK: Only runs if the cache document doesn't exist at all
      // (e.g. before the Cloud Function runs for the very first time).
      // ======================================================================
      final snapshot = await firestore
          .collection('users')
          .orderBy('totalExp', descending: true)
          .limit(limit)
          .get();

      final List<Map<String, dynamic>> usersData = [];
      final List<UserEntity> users = [];
      final fetchTime = DateTime.now();
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = data['id'] ?? doc.id;
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
          if (kDebugMode) debugPrint('Corrupted user in fetch: $e');
        }
      }

      // Initialize the cache so future reads use the O(1) fetch.
      // Wrapped in try-catch because clients may not have write permissions to metadata collection.
      try {
        await cacheDocRef.set({
          'lastUpdated': FieldValue.serverTimestamp(),
          'users': usersData,
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to set metadata leaderboard cache: $e');
        }
      }

      return Right(LeaderboardResult(users: users, lastUpdated: fetchTime));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
