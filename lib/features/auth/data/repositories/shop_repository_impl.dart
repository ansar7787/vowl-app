import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Concrete implementation of [ShopRepository] managing virtual currency
/// balances, daily reward claims, hint packs, Kids Zone purchases, and
/// accessory management.
///
/// All write operations that involve balance checks or duplicate-claim guards
/// run inside Firestore transactions, eliminating double-spend and double-claim
/// race conditions.
class ShopRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements ShopRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  ShopRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // updateUserCoins
  // ---------------------------------------------------------------------------

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

      // Always use a transaction to keep the coin history log consistent with
      // the balance change — even when no title is provided.
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;
        final updates = <String, dynamic>{
          'coins': FieldValue.increment(amountChange),
        };

        if (title != null) {
          var history = <Map<String, dynamic>>[];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(
              (data['coinHistory'] as List<dynamic>)
                  .whereType<Map<Object?, Object?>>()
                  .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
            );
          }
          history.insert(0, {
            'title': title,
            'amount': amountChange,
            'isEarned': isEarned ?? (amountChange > 0),
            'date': DateTime.now().toIso8601String(),
          });
          if (history.length > UserGameConstants.kActivityHistoryLimit) {
            history = history.sublist(
              0,
              UserGameConstants.kActivityHistoryLimit,
            );
          }
          updates['coinHistory'] = history;
        }

        transaction.update(docRef, updates);
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // awardKidsCoins
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> awardKidsCoins(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      // FieldValue.increment is atomically safe for server-side increments.
      await _firestore.collection('users').doc(user.uid).update({
        'kidsCoins': FieldValue.increment(amount),
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimDailyGift
  // ---------------------------------------------------------------------------

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

        final bool available =
            lastGift == null ||
            lastGift.year != now.year ||
            lastGift.month != now.month ||
            lastGift.day != now.day;

        if (!available) {
          return Left(AuthFailure('Daily gift already claimed today'));
        }

        // Reward scales with the day of month to provide variety.
        final reward =
            UserGameConstants.kDailyGiftBaseReward +
            (now.day % 5) * UserGameConstants.kDailyGiftCycleIncrement;

        transaction.update(docRef, {
          'coins': FieldValue.increment(reward),
          'lastDailyRewardDate': Timestamp.now(),
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimDailyChest
  // ---------------------------------------------------------------------------

  /// Claims the daily chest reward of [amount] coins.
  ///
  /// Duplicate-claim guard: reads [lastDailyRewardDate] inside the transaction
  /// and rejects if the chest was already claimed today. Shares the same date
  /// field as [claimDailyGift] — the two rewards are mutually exclusive within
  /// the same calendar day by design.
  @override
  Future<Either<Failure, void>> claimDailyChest(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      _log(
        'ShopRepository: Daily Chest claim initiated for ${user.uid} (amount: $amount)',
      );

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(AuthFailure('User data not found'));
        }

        // Guard: reject if chest was already claimed today.
        final lastRaw = doc.data()!['lastDailyRewardDate'];
        if (lastRaw != null) {
          final lastClaim = (lastRaw as Timestamp).toDate();
          final now = DateTime.now();
          final alreadyClaimed =
              lastClaim.year == now.year &&
              lastClaim.month == now.month &&
              lastClaim.day == now.day;
          if (alreadyClaimed) {
            return Left(AuthFailure('Daily chest already claimed today'));
          }
        }

        transaction.update(docRef, {
          'coins': FieldValue.increment(amount),
          'lastDailyRewardDate': Timestamp.now(),
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      _log('ShopRepository: Daily Chest ERROR: $e');
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimKidsDailyReward
  // ---------------------------------------------------------------------------

  /// Claims the Kids Zone daily reward of [amount] kids-coins.
  ///
  /// Duplicate-claim guard: reads [lastKidsDailyRewardDate] inside the
  /// transaction and rejects if already claimed today.
  @override
  Future<Either<Failure, void>> claimKidsDailyReward(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      _log('ShopRepository: Kids Daily Reward claim initiated for ${user.uid}');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(AuthFailure('User data not found'));
        }

        // Guard: reject if kids reward was already claimed today.
        final lastRaw = doc.data()!['lastKidsDailyRewardDate'];
        if (lastRaw != null) {
          final lastClaim = (lastRaw as Timestamp).toDate();
          final now = DateTime.now();
          final alreadyClaimed =
              lastClaim.year == now.year &&
              lastClaim.month == now.month &&
              lastClaim.day == now.day;
          if (alreadyClaimed) {
            return Left(AuthFailure('Kids daily reward already claimed today'));
          }
        }

        transaction.update(docRef, {
          'kidsCoins': FieldValue.increment(amount),
          'lastKidsDailyRewardDate': Timestamp.now(),
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      _log('ShopRepository: Kids Daily Reward ERROR: $e');
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // useHint
  // ---------------------------------------------------------------------------

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

        final hintCount = (snapshot.data()?['hintCount'] as num?)?.toInt() ?? 0;
        if (hintCount > 0) {
          transaction.update(docRef, {'hintCount': FieldValue.increment(-1)});
          return const Right<Failure, void>(null);
        } else {
          _log('ShopRepository: useHint failed — no hints available.');
          return Left(ServerFailure('No hints available'));
        }
      });
    } catch (e) {
      _log('ShopRepository: useHint ERROR: $e');
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // purchaseHint
  // ---------------------------------------------------------------------------

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

        var history = <Map<String, dynamic>>[];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(
            (data['coinHistory'] as List<dynamic>)
                .whereType<Map<Object?, Object?>>()
                .map((m) => m.map((k, v) => MapEntry(k.toString(), v))),
          );
        }
        history.insert(0, {
          'title': 'Purchased Hint Pack',
          'amount': -cost,
          'isEarned': false,
          'date': DateTime.now().toIso8601String(),
        });
        if (history.length > UserGameConstants.kActivityHistoryLimit) {
          history = history.sublist(0, UserGameConstants.kActivityHistoryLimit);
        }

        transaction.update(docRef, {
          'coins': FieldValue.increment(-cost),
          'hintCount': FieldValue.increment(hintAmount),
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // awardKidsSticker
  // ---------------------------------------------------------------------------

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
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // updateKidsMascot
  // ---------------------------------------------------------------------------

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
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // buyKidsAccessory
  // ---------------------------------------------------------------------------

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
        if (!snapshot.exists) throw Exception('User not found');

        final data = snapshot.data()!;
        final currentCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(
          data['kidsOwnedAccessories'] as List? ?? [],
        );

        // Idempotent: silently succeed if already owned.
        if (owned.contains(accessoryId)) return;

        if (currentCoins < cost) throw Exception('Not enough Kids Coins');

        transaction.update(docRef, {
          'kidsCoins': currentCoins - cost,
          'kidsOwnedAccessories': FieldValue.arrayUnion([accessoryId]),
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // equipKidsAccessory
  // ---------------------------------------------------------------------------

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
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
