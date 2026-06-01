import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  GamificationRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

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
        Map<String, int> dailyHistory = {};
        List<Map<String, dynamic>> activities = [];
        Map<String, List<int>> completedLevels = {};
        Map<String, int> unlockedLevels = {};

        if (data['dailyXpHistory'] != null) {
          dailyHistory = Map<String, int>.from(data['dailyXpHistory']);
        }
        if (data['recentActivities'] != null) {
          activities = List<Map<String, dynamic>>.from(
            data['recentActivities'],
          );
        }
        if (data['completedLevels'] != null) {
          completedLevels = (data['completedLevels'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<int>.from(value)));
        }
        if (data['unlockedLevels'] != null) {
          unlockedLevels = Map<String, int>.from(data['unlockedLevels']);
        }

        final categoryCompleted = completedLevels[gameType] ?? [];
        final bool isReplay = categoryCompleted.contains(level);

        double xpMultiplier = 1.0;
        if (data['hasPermanentXPBoost'] == true) xpMultiplier *= 1.1;

        final doubleXPExpiry = data['doubleXPExpiry'] != null
            ? (data['doubleXPExpiry'] as Timestamp).toDate()
            : null;
        if (doubleXPExpiry != null &&
            doubleXPExpiry.isAfter(DateTime.now())) {
          xpMultiplier *= 2.0;
        }

        final baseXp = isReplay ? (xpIncrease * 0.5) : xpIncrease;
        final finalXpIncrease = (baseXp * xpMultiplier).round();

        if (!isReplay) {
          categoryCompleted.add(level);
          completedLevels[gameType] = categoryCompleted;
        }

        final now = DateTime.now();
        final todayKey =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final currentDaily = dailyHistory[todayKey] ?? 0;
        dailyHistory[todayKey] = currentDaily + finalXpIncrease;

        final newActivity = {
          'title': 'Quest Completed',
          'subtitle': '+$finalXpIncrease XP · +$coinIncrease Coins',
          'timestamp': Timestamp.now(),
          'type': 'quest',
        };
        activities.insert(0, newActivity);
        if (activities.length > 10) {
          activities = activities.sublist(0, 10);
        }

        int finalCoinIncrease = (isReplay && !isDoubleReward) ? 0 : coinIncrease;
        final userExp = data['totalExp'] as int? ?? 0;
        final userLevel = (userExp / 100).floor() + 1;

        if (!isReplay && (data['isPremium'] == true || userLevel >= 100)) {
          finalCoinIncrease = coinIncrease * 2;
        }

        final kidsGames = {
          'alphabet', 'numbers', 'colors', 'shapes', 'animals',
          'fruits', 'family', 'school', 'verbs', 'routine',
          'emotions', 'prepositions', 'phonics', 'day_night',
          'nature', 'home_kids', 'food_kids', 'transport',
          'time', 'opposites', 'body_parts', 'clothing',
        };
        final isKidsGame = kidsGames.contains(gameType);

        final currentUnlocked = unlockedLevels[gameType] ?? 1;
        if (level >= currentUnlocked) {
          unlockedLevels[gameType] = level + 1;
        }

        List<Map<String, dynamic>> history = [];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(data['coinHistory']);
        }

        final entry = {
          'title': 'Quest Reward - ${gameType.toUpperCase()}',
          'amount': finalCoinIncrease,
          'isEarned': true,
          'date': DateTime.now().toIso8601String(),
        };

        history.insert(0, entry);
        if (history.length > 10) history.removeLast();

        transaction.update(docRef, {
          'totalExp': (userExp + finalXpIncrease),
          isKidsGame ? 'kidsCoins' : 'coins': FieldValue.increment(
            finalCoinIncrease,
          ),
          'coinHistory': history,
          'dailyXpHistory': dailyHistory,
          'recentActivities': activities,
          'completedLevels': completedLevels,
          'unlockedLevels': unlockedLevels,
        });
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        Map<String, int> unlockedLevels = {};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['unlockedLevels'] != null) {
            unlockedLevels = Map<String, int>.from(data['unlockedLevels']);
          }
        }

        final currentUnlocked = unlockedLevels[categoryId] ?? 1;
        if (newLevel > currentUnlocked) {
          unlockedLevels[categoryId] = newLevel;
          await docRef.update({'unlockedLevels': unlockedLevels});
        }
        return const Right(null);
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        Map<String, int> currentStats = {};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['categoryStats'] != null) {
            currentStats = Map<String, int>.from(data['categoryStats']);
          }
        }

        int currentScore = currentStats[categoryId] ?? 50;
        int newScore = isCorrect ? currentScore + 10 : currentScore - 10;
        if (newScore > 100) newScore = 100;
        if (newScore < 0) newScore = 0;

        currentStats[categoryId] = newScore;

        await docRef.update({'categoryStats': currentStats});
        return const Right(null);
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> awardBadge(String badgeId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'badges': FieldValue.arrayUnion([badgeId]),
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> repairStreak(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("User not found");
          final currentCoins =
              (snapshot.data()?['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception("Not enough coins");

          final history = List<Map<String, dynamic>>.from(
            snapshot.data()?['coinHistory'] ?? [],
          );
          final entry = {
            'title': 'Repaired Streak',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };
          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'coinHistory': history,
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          if (!doc.exists || doc.data() == null) {
            throw Exception('User data not found');
          }

          final data = doc.data()!;
          final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception('Not enough coins');

          List<Map<String, dynamic>> history = [];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(data['coinHistory']);
          }

          final entry = {
            'title': 'Purchased Streak Freeze',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };

          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'streakFreezes': FieldValue.increment(1),
            'coinHistory': history,
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateDoubleXP(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          if (!doc.exists || doc.data() == null) {
            throw Exception('User data not found');
          }

          final data = doc.data()!;
          final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception('Not enough coins');

          List<Map<String, dynamic>> history = [];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(data['coinHistory']);
          }

          final entry = {
            'title': 'Purchased Double XP',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };

          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          final expiry = DateTime.now().add(const Duration(hours: 24));
          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'doubleXP': 1,
            'doubleXPExpiry': Timestamp.fromDate(expiry),
            'coinHistory': history,
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
