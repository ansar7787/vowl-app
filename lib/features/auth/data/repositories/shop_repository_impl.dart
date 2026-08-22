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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      // Always use a transaction to keep the coin history log consistent with
      // the balance change — even when no title is provided.
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = doc.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

        // Only a spend (negative delta) can ever overdraw the balance;
        // earning coins is always safe to apply unconditionally. This check
        // did not exist before — any caller passing a negative amountChange
        // larger than the current balance could silently push coins below
        // zero, since FieldValue.increment has no floor of its own.
        if (amountChange < 0 && currentCoins + amountChange < 0) {
          _log(
            'ShopRepository: updateUserCoins rejected — insufficient balance for ${user.uid}.',
          );
          return Left(AuthFailure('insufficient-coins'));
        }

        final updates = <String, dynamic>{
          'coins': FieldValue.increment(amountChange),
        };
        
        if (amountChange > 0) {
          updates['lastRewardTimestamp'] = FieldValue.serverTimestamp();
        }

        if (title != null) {
          final history = _recordCoinHistory(
            _parseMapList(data['coinHistory']),
            titleKey: title,
            amount: amountChange,
            isEarned: isEarned ?? (amountChange > 0),
          );
          updates['coinHistory'] = history;
        }

        transaction.update(docRef, updates);
        return const Right<Failure, void>(null);
      });
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      // FieldValue.increment is atomically safe for server-side increments.
      await _firestore.collection('users').doc(user.uid).update({
        'kidsCoins': FieldValue.increment(amount),
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final userData = UserModel.fromMap(doc.data()!);
        final now = DateTime.now();
        final lastGift = userData.lastDailyRewardDate;

        final bool available =
            lastGift == null || !_isSameCalendarDay(lastGift, now);

        if (!available) {
          return Left(AuthFailure('daily-gift-already-claimed'));
        }

        // Reward scales with the day of month to provide variety.
        final reward =
            UserGameConstants.kDailyGiftBaseReward +
            (now.day % 5) * UserGameConstants.kDailyGiftCycleIncrement;

        final history = _recordCoinHistory(
          _parseMapList(doc.data()!['coinHistory']),
          titleKey: 'coin_history.daily_gift',
          amount: reward,
          isEarned: true,
        );

        transaction.update(docRef, {
          'coins': FieldValue.increment(reward),
          'coinHistory': history,
          'lastDailyRewardDate': Timestamp.now(),
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      _log(
        'ShopRepository: Daily Chest claim initiated for ${user.uid} (amount: $amount)',
      );

      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        // Guard: reject if chest was already claimed today. Parsed through
        // UserModel.fromMap (same as claimDailyGift) rather than a direct
        // `as Timestamp` cast — the raw cast would throw if this field was
        // ever anything else (an ISO string from a migration, for example),
        // where UserModel's parser already handles that defensively.
        final userData = UserModel.fromMap(doc.data()!);
        final lastClaim = userData.lastDailyRewardDate;
        if (lastClaim != null &&
            _isSameCalendarDay(lastClaim, DateTime.now())) {
          return Left(AuthFailure('daily-chest-already-claimed'));
        }

        final history = _recordCoinHistory(
          _parseMapList(doc.data()!['coinHistory']),
          titleKey: 'coin_history.daily_chest',
          amount: amount,
          isEarned: true,
        );

        transaction.update(docRef, {
          'coins': FieldValue.increment(amount),
          'coinHistory': history,
          'lastDailyRewardDate': Timestamp.now(),
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      _log('ShopRepository: Kids Daily Reward claim initiated for ${user.uid}');

      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        // Same defensive-parsing rationale as claimDailyChest above.
        final userData = UserModel.fromMap(doc.data()!);
        final lastClaim = userData.lastKidsDailyRewardDate;
        if (lastClaim != null &&
            _isSameCalendarDay(lastClaim, DateTime.now())) {
          return Left(AuthFailure('kids-daily-reward-already-claimed'));
        }

        transaction.update(docRef, {
          'kidsCoins': FieldValue.increment(amount),
          'lastKidsDailyRewardDate': Timestamp.now(),
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final hintCount = (snapshot.data()?['hintCount'] as num?)?.toInt() ?? 0;
        if (hintCount > 0) {
          transaction.update(docRef, {'hintCount': FieldValue.increment(-1)});
          return const Right<Failure, void>(null);
        } else {
          _log('ShopRepository: useHint failed — no hints available.');
          return Left(AuthFailure('no-hints-available'));
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = doc.data()!;
        final coins = (data['coins'] as num?)?.toInt() ?? 0;
        if (coins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.purchased_hint_pack',
          amount: -cost,
          isEarned: false,
        );

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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = snapshot.data()!;
        final currentCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(
          data['kidsOwnedAccessories'] as List? ?? [],
        );

        // Idempotent: silently succeed if already owned.
        if (owned.contains(accessoryId)) {
          return const Right<Failure, void>(null);
        }

        if (currentCoins < cost) {
          return Left(AuthFailure('insufficient-kids-coins'));
        }

        transaction.update(docRef, {
          'kidsCoins': currentCoins - cost,
          'kidsOwnedAccessories': FieldValue.arrayUnion([accessoryId]),
        });
        return const Right<Failure, void>(null);
      });
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      await _firestore.collection('users').doc(user.uid).update({
        'kidsEquippedAccessory': accessoryId,
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // buyKidsFurniture
  // ---------------------------------------------------------------------------

  /// Replaces ProfileBloc._onBuyFurniture's previous client-side
  /// read-then-write via a generic UpdateUser call (flagged in that
  /// method's own doc comment as needing exactly this).
  @override
  Future<Either<Failure, void>> buyKidsFurniture({
    required String category,
    required String furnitureId,
    required int cost,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = snapshot.data()!;
        final currentCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(
          data['kidsOwnedFurniture'] as List? ?? [],
        );
        final equipped = Map<String, String>.from(
          data['kidsEquippedFurniture'] as Map? ?? {},
        );

        // Re-equipping something already owned is always free — only a new
        // purchase needs the balance check.
        final alreadyOwned = owned.contains(furnitureId);
        if (!alreadyOwned && currentCoins < cost) {
          return Left(AuthFailure('insufficient-kids-coins'));
        }

        equipped[category] = furnitureId;
        final updates = <String, dynamic>{'kidsEquippedFurniture': equipped};
        if (!alreadyOwned) {
          updates['kidsCoins'] = currentCoins - cost;
          updates['kidsOwnedFurniture'] = FieldValue.arrayUnion([furnitureId]);
        }

        transaction.update(docRef, updates);
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // buyVowlMascot
  // ---------------------------------------------------------------------------

  /// Replaces ProfileBloc._onBuyVowlMascot's previous client-side
  /// read-then-write via a generic UpdateUser call.
  @override
  Future<Either<Failure, void>> buyVowlMascot({
    required String mascotId,
    required int cost,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = snapshot.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(
          data['vowlOwnedMascots'] as List? ?? [],
        );

        final alreadyOwned = owned.contains(mascotId);
        if (!alreadyOwned && currentCoins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final updates = <String, dynamic>{'vowlMascot': mascotId};
        if (!alreadyOwned) {
          updates['coins'] = currentCoins - cost;
          updates['vowlOwnedMascots'] = FieldValue.arrayUnion([mascotId]);
          updates['coinHistory'] = _recordCoinHistory(
            _parseMapList(data['coinHistory']),
            titleKey: 'coin_history.purchased_mascot',
            amount: -cost,
            isEarned: false,
          );
        }

        transaction.update(docRef, updates);
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // buyVowlAccessory
  // ---------------------------------------------------------------------------

  /// Replaces ProfileBloc._onBuyVowlAccessory's previous client-side
  /// read-then-write via a generic UpdateUser call (flagged in that
  /// method's own doc comment as needing exactly this).
  @override
  Future<Either<Failure, void>> buyVowlAccessory({
    required String accessoryId,
    required int cost,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = snapshot.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        final owned = List<String>.from(
          data['vowlOwnedAccessories'] as List? ?? [],
        );

        final alreadyOwned = owned.contains(accessoryId);
        if (!alreadyOwned && currentCoins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final updates = <String, dynamic>{'vowlEquippedAccessory': accessoryId};
        if (!alreadyOwned) {
          updates['coins'] = currentCoins - cost;
          updates['vowlOwnedAccessories'] = FieldValue.arrayUnion([
            accessoryId,
          ]);
          updates['coinHistory'] = _recordCoinHistory(
            _parseMapList(data['coinHistory']),
            titleKey: 'coin_history.purchased_accessory',
            amount: -cost,
            isEarned: false,
          );
        }

        transaction.update(docRef, updates);
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses a Firestore list of coin-history entries defensively. Local
  /// counterpart to the equivalent helper in GamificationRepositoryImpl —
  /// Dart's per-file privacy means neither can import the other's.
  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    return (raw as List<dynamic>)
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Prepends a coin-history entry and trims to the configured retention
  /// limit. Shared by [updateUserCoins] and [purchaseHint].
  ///
  /// [titleKey] is a stable lookup key, never English display text — see
  /// [GamificationRepositoryImpl]'s class doc for the localization rationale
  /// (the same fix was applied there for the identical reason). [params]
  /// carries any values the presentation layer needs to interpolate.
  static List<Map<String, dynamic>> _recordCoinHistory(
    List<Map<String, dynamic>> existing, {
    required String titleKey,
    required int amount,
    required bool isEarned,
    Map<String, dynamic>? params,
  }) {
    final updated = List<Map<String, dynamic>>.from(existing)
      ..insert(0, {
        'titleKey': titleKey,
        'params': ?params,
        'amount': amount,
        'isEarned': isEarned,
        'date': DateTime.now().toIso8601String(),
      });
    if (updated.length > UserGameConstants.kActivityHistoryLimit) {
      return updated.sublist(0, UserGameConstants.kActivityHistoryLimit);
    }
    return updated;
  }

  /// True if [a] and [b] fall on the same calendar day (year/month/day) in
  /// local time. Used by every "claim once per day" guard in this file.
  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
