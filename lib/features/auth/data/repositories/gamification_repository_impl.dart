import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Concrete implementation of [GamificationRepository] handling atomic writes
/// and progress tracking.
///
/// Every read-then-write operation executes inside a [FirebaseFirestore]
/// transaction to eliminate concurrency race conditions, even on multiple
/// concurrent devices for the same user.
class GamificationRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements GamificationRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  GamificationRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // updateUserRewards
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;

        // ---- Parse existing fields ----
        var dailyHistory = <String, int>{};
        if (data['dailyXpHistory'] != null) {
          dailyHistory = Map<String, int>.from(
            data['dailyXpHistory'] as Map<Object?, Object?>,
          );
        }

        var activities = <Map<String, dynamic>>[];
        if (data['recentActivities'] != null) {
          activities = List<Map<String, dynamic>>.from(
            (data['recentActivities'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }

        var completedLevels = <String, List<int>>{};
        if (data['completedLevels'] != null) {
          completedLevels = (data['completedLevels'] as Map<Object?, Object?>)
              .map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as List<dynamic>)
                      .map((v) => (v as num?)?.toInt() ?? 0)
                      .toList(),
                ),
              );
        }

        var unlockedLevels = <String, int>{};
        if (data['unlockedLevels'] != null) {
          unlockedLevels = Map<String, int>.from(
            (data['unlockedLevels'] as Map<Object?, Object?>).map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ),
          );
        }

        var coinHistoryList = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          coinHistoryList = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }

        // ---- Replay detection ----
        final categoryCompleted = completedLevels[gameType] ?? [];
        final bool isReplay = categoryCompleted.contains(level);

        // ---- XP multiplier calculation ----
        var xpMultiplier = 1.0;
        if (data['hasPermanentXPBoost'] == true) {
          xpMultiplier *= UserGameConstants.kPermanentXpBoostMultiplier;
        }
        final doubleXPExpiry = data['doubleXPExpiry'] != null
            ? (data['doubleXPExpiry'] as Timestamp).toDate()
            : null;
        if (doubleXPExpiry != null && doubleXPExpiry.isAfter(DateTime.now())) {
          xpMultiplier *= UserGameConstants.kDoubleXpMultiplier;
        }

        final baseXp = isReplay
            ? (xpIncrease * UserGameConstants.kReplayXpFraction)
            : xpIncrease.toDouble();
        final finalXpIncrease = (baseXp * xpMultiplier).round();

        // ---- Completed & unlocked levels ----
        if (!isReplay) {
          categoryCompleted.add(level);
          completedLevels[gameType] = categoryCompleted;
        }

        final currentUnlocked = math.max(10, unlockedLevels[gameType] ?? 10);
        if (level >= currentUnlocked) {
          // Free levels (1-10) or Premium users automatically unlock the next level.
          // Otherwise, the user must explicitly purchase the next level via the Toll Gate.
          if (level < 10 || data['isPremium'] == true) {
            unlockedLevels[gameType] = level + 1;
          }
        }

        // ---- Daily XP history ----
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final currentDaily = dailyHistory[todayKey] ?? 0;
        dailyHistory[todayKey] = currentDaily + finalXpIncrease;

        // ---- Trim daily history to the configured limit ----
        if (dailyHistory.length > UserGameConstants.kDailyXpHistoryLimit) {
          final sortedKeys = dailyHistory.keys.toList()..sort();
          final toRemove =
              sortedKeys.length - UserGameConstants.kDailyXpHistoryLimit;
          for (var i = 0; i < toRemove; i++) {
            dailyHistory.remove(sortedKeys[i]);
          }
        }

        // ---- Recent activities ----
        final newActivity = <String, dynamic>{
          'title': 'Quest Completed',
          'subtitle': '+$finalXpIncrease XP · +$coinIncrease Coins',
          'timestamp': Timestamp.now(),
          'type': 'quest',
        };
        activities.insert(0, newActivity);
        if (activities.length > UserGameConstants.kActivityHistoryLimit) {
          activities = activities.sublist(
            0,
            UserGameConstants.kActivityHistoryLimit,
          );
        }

        // ---- Coin reward calculation ----
        final userExp = (data['totalExp'] as num?)?.toInt() ?? 0;
        final userLevel = (userExp / UserGameConstants.kXpPerLevel).floor() + 1;

        // Kids Zone games route to kidsCoins; other games route to coins.
        // Use UserGameConstants.kKidsGameTypes (static const Set) instead of
        // instantiating a new Set on every transaction invocation.
        final isKidsGame = UserGameConstants.kKidsGameTypes.contains(gameType);

        var finalCoinIncrease = (isReplay && !isDoubleReward)
            ? 0
            : coinIncrease;
        if (!isReplay && (data['isPremium'] == true || userLevel >= 100)) {
          finalCoinIncrease = coinIncrease * 2;
        }

        // ---- Coin history ----
        final coinEntry = <String, dynamic>{
          'title': 'Quest Reward - ${gameType.toUpperCase()}',
          'amount': finalCoinIncrease,
          'isEarned': true,
          'date': now.toIso8601String(),
        };
        coinHistoryList.insert(0, coinEntry);
        if (coinHistoryList.length > UserGameConstants.kActivityHistoryLimit) {
          coinHistoryList = coinHistoryList.sublist(
            0,
            UserGameConstants.kActivityHistoryLimit,
          );
        }

        // ---- Atomic update ----
        transaction.update(docRef, {
          'totalExp': userExp + finalXpIncrease,
          isKidsGame ? 'kidsCoins' : 'coins': FieldValue.increment(
            finalCoinIncrease,
          ),
          'coinHistory': coinHistoryList,
          'dailyXpHistory': dailyHistory,
          'recentActivities': activities,
          'completedLevels': completedLevels,
          'unlockedLevels': unlockedLevels,
        });
      });

      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // updateUnlockedLevel
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        var unlockedLevels = <String, int>{};
        if (doc.exists && doc.data() != null) {
          final raw = doc.data()!['unlockedLevels'];
          if (raw != null) {
            unlockedLevels = Map<String, int>.from(
              (raw as Map<Object?, Object?>).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              ),
            );
          }
        }

        final currentUnlocked = math.max(10, unlockedLevels[categoryId] ?? 10);
        if (newLevel > currentUnlocked) {
          unlockedLevels[categoryId] = newLevel;
          transaction.update(docRef, {'unlockedLevels': unlockedLevels});
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // updateCategoryStats
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        var currentStats = <String, int>{};
        if (doc.exists && doc.data() != null) {
          final raw = doc.data()!['categoryStats'];
          if (raw != null) {
            currentStats = Map<String, int>.from(
              (raw as Map<Object?, Object?>).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              ),
            );
          }
        }

        final currentScore =
            currentStats[categoryId] ?? UserGameConstants.kCategoryStatDefault;
        var newScore = isCorrect
            ? currentScore + UserGameConstants.kCategoryStatStep
            : currentScore - UserGameConstants.kCategoryStatStep;
        newScore = newScore.clamp(
          UserGameConstants.kCategoryStatMin,
          UserGameConstants.kCategoryStatMax,
        );

        currentStats[categoryId] = newScore;
        transaction.update(docRef, {'categoryStats': currentStats});
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // awardBadge
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> awardBadge(String badgeId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      await _firestore.collection('users').doc(user.uid).update({
        'badges': FieldValue.arrayUnion([badgeId]),
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // repairStreak
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> repairStreak(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('User not found');

        final data = snapshot.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) throw Exception('Not enough coins');

        var history = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
        history.insert(0, {
          'title': 'Repaired Streak',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        });
        if (history.length > UserGameConstants.kActivityHistoryLimit) {
          history = history.sublist(0, UserGameConstants.kActivityHistoryLimit);
        }

        final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
        // Repairing a broken streak always sets it to at least 2 so the
        // UI shows a meaningful restored value, even when the streak was 0 or 1.
        final newStreak = currentStreak <= 1 ? 2 : currentStreak + 1;

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'coinHistory': history,
          'currentStreak': newStreak,
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // purchaseStreakFreeze
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) throw Exception('Not enough coins');

        var history = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
        history.insert(0, {
          'title': 'Purchased Streak Freeze',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        });
        if (history.length > UserGameConstants.kActivityHistoryLimit) {
          history = history.sublist(0, UserGameConstants.kActivityHistoryLimit);
        }

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'streakFreezes': FieldValue.increment(1),
          'coinHistory': history,
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // activateDoubleXP
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> activateDoubleXP(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) throw Exception('Not enough coins');

        var history = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
        history.insert(0, {
          'title': 'Purchased Double XP',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        });
        if (history.length > UserGameConstants.kActivityHistoryLimit) {
          history = history.sublist(0, UserGameConstants.kActivityHistoryLimit);
        }

        final expiry = DateTime.now().add(const Duration(hours: 24));
        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'doubleXP': 1,
          'doubleXPExpiry': Timestamp.fromDate(expiry),
          'coinHistory': history,
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // purchaseLevelUnlock
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> purchaseLevelUnlock({
    required String gameType,
    required int cost,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) throw Exception('Not enough coins');

        var history = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
        history.insert(0, {
          'title': 'Unlocked ${gameType.toUpperCase()} Level',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        });
        if (history.length > UserGameConstants.kActivityHistoryLimit) {
          history = history.sublist(0, UserGameConstants.kActivityHistoryLimit);
        }

        var unlockedLevels = <String, int>{};
        if (data['unlockedLevels'] != null) {
          unlockedLevels = Map<String, int>.from(
            (data['unlockedLevels'] as Map<Object?, Object?>).map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
            ),
          );
        }

        final currentUnlocked = math.max(10, unlockedLevels[gameType] ?? 10);
        unlockedLevels[gameType] = currentUnlocked + 3;

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'unlockedLevels': unlockedLevels,
          'coinHistory': history,
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }
}
