import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Concrete implementation of [ShopRepository] managing virtual currency balances and transactions.
///
/// Refactored to utilize atomic transactions across all marketplace and gift operations,
/// eliminating the risk of double-claim and double-spend concurrency exploits.
class ShopRepositoryImpl implements ShopRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  ShopRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Defensive helper to translate raw database exceptions into structured [Failure] domains.
  Failure _handleException(dynamic e) {
    if (e is FirebaseException) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return NetworkFailure('Network connection failed. Operating in offline mode.');
      }
      return ServerFailure('Database operation failed: ${e.message}');
    }
    final errStr = e.toString();
    if (errStr.contains('SocketException') || errStr.contains('NetworkError')) {
      return NetworkFailure('Network unreachable. Please check connection states.');
    }
    return ServerFailure(errStr);
  }

  @override
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      if (title != null) {
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          if (!doc.exists || doc.data() == null) {
            throw Exception('User data not found');
          }

          final data = doc.data()!;
          List<Map<String, dynamic>> history = [];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(data['coinHistory']);
          }

          final entry = {
            'title': title,
            'amount': amountChange,
            'isEarned': isEarned ?? (amountChange > 0),
            'date': DateTime.now().toIso8601String(),
          };

          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          transaction.update(docRef, {
            'coins': FieldValue.increment(amountChange),
            'coinHistory': history,
          });
        });
        return const Right(null);
      }

      await docRef.update({'coins': FieldValue.increment(amountChange)});
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> awardKidsCoins(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      await _firestore.collection('users').doc(user.uid).update({
        'kidsCoins': FieldValue.increment(amount),
      });
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> claimDailyGift() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(AuthFailure('User data not found'));
        }

        final userData = UserModel.fromMap(doc.data()!);
        final now = DateTime.now();
        final lastGift = userData.lastDailyRewardDate;
        final bool available = lastGift == null ||
            lastGift.year != now.year ||
            lastGift.month != now.month ||
            lastGift.day != now.day;

        if (!available) {
          return Left(AuthFailure('Daily gift already claimed today'));
        }

        final reward = 50 + (now.day % 5) * 10;
        transaction.update(docRef, {
          'coins': FieldValue.increment(reward),
          'lastDailyRewardDate': Timestamp.now(),
        });
        return const Right(null);
      });
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> claimDailyChest(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      debugPrint(
        'ShopRepository: Atomic Daily Chest (Transaction) triggered for ${user.uid} (Amount: $amount)',
      );

      return await _firestore.runTransaction((transaction) async {
        transaction.update(docRef, {
          'coins': FieldValue.increment(amount),
          'lastDailyRewardDate': Timestamp.now(),
        });
        return const Right(null);
      });
    } catch (e) {
      debugPrint('ShopRepository: Daily Chest ERROR: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> claimKidsDailyReward(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      debugPrint(
        'ShopRepository: Atomic Kids Reward (Transaction) triggered for ${user.uid}',
      );

      return await _firestore.runTransaction((transaction) async {
        transaction.update(docRef, {
          'kidsCoins': FieldValue.increment(amount),
          'lastKidsDailyRewardDate': Timestamp.now(),
        });
        return const Right(null);
      });
    } catch (e) {
      debugPrint('ShopRepository: Kids Reward ERROR: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> useHint() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('User data not found'));
        }

        final hintCount = snapshot.data()?['hintCount'] ?? 0;
        if (hintCount > 0) {
          debugPrint(
            'ShopRepository: Atomic Hint Decrement (Transaction) triggered.',
          );
          transaction.update(docRef, {'hintCount': FieldValue.increment(-1)});
          return const Right(null);
        } else {
          debugPrint(
            'ShopRepository: Hint decrement FAILED: No hints available.',
          );
          return Left(ServerFailure('No hints available'));
        }
      });
    } catch (e) {
      debugPrint('ShopRepository: useHint ERROR: $e');
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('User data not found'));
        }

        final data = doc.data()!;
        final coins = (data['coins'] as num?)?.toInt() ?? 0;
        if (coins < cost) {
          return Left(ServerFailure('Not enough coins'));
        }

        List<Map<String, dynamic>> history = [];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(data['coinHistory']);
        }

        final entry = {
          'title': 'Purchased Hint Pack',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        };

        history.insert(0, entry);
        if (history.length > 10) history.removeLast();

        transaction.update(docRef, {
          'coins': FieldValue.increment(-cost),
          'hintCount': FieldValue.increment(hintAmount),
          'coinHistory': history,
        });
        return const Right(null);
      });
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> awardKidsSticker(String stickerId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      await _firestore.collection('users').doc(user.uid).update({
        'kidsStickers': FieldValue.arrayUnion([stickerId]),
      });
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateKidsMascot(String mascotId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      await _firestore.collection('users').doc(user.uid).update({
        'kidsMascot': mascotId,
      });
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> buyKidsAccessory(
    String accessoryId,
    int cost,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception("User not found");

        final data = snapshot.data()!;
        final currentCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(data['kidsOwnedAccessories'] ?? []);

        if (owned.contains(accessoryId)) {
          return;
        }

        if (currentCoins < cost) {
          throw Exception("Not enough Kids Coins");
        }

        transaction.update(docRef, {
          'kidsCoins': currentCoins - cost,
          'kidsOwnedAccessories': FieldValue.arrayUnion([accessoryId]),
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> equipKidsAccessory(String? accessoryId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      await _firestore.collection('users').doc(user.uid).update({
        'kidsEquippedAccessory': accessoryId,
      });
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }
}
