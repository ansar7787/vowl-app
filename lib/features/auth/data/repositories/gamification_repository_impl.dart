import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Concrete implementation of [GamificationRepository] handling atomic writes
/// and progress tracking.
///
/// Every read-then-write operation executes inside a [FirebaseFirestore]
/// transaction to eliminate concurrency race conditions, even on multiple
/// concurrent devices for the same user. Business-rule rejections (a doc
/// that doesn't exist, an insufficient balance) are returned as a typed
/// `Left(Failure)` value *from* the transaction closure rather than thrown —
/// see [updateUserRewards] and its siblings. Throwing a plain [Exception] for
/// these cases (the previous approach) meant the type information was lost
/// the moment it crossed into [handleFirebaseException]'s generic catch-all,
/// turning e.g. "not enough coins" into an indistinguishable `ServerFailure`.
///
/// ### `lastEarnedStars` — known architectural debt, not touched here
/// [lastEarnedStars] is a `static` [ValueNotifier] that the Victory Screen
/// listens to directly (outside this review's visibility) to trigger its
/// star animation. This bypasses the [GamificationRepository] abstraction
/// entirely — it isn't part of that interface, so any consumer has to import
/// this *concrete* class to use it, which undercuts the reason to code
/// against the interface in the first place (harder to test, harder to swap
/// implementations, and — being `static` — shared process-wide rather than
/// scoped to a session). It's deliberately left in place here because
/// retyping or removing it would break that Victory Screen listener, which
/// lives outside this feature slice. Two scoped, non-breaking fixes were
/// applied instead:
///   1. The assignment now happens *after* the transaction commits, not
///      inside the transaction closure. Firestore may re-invoke a
///      transaction closure on write contention, and `lastEarnedStars.value
///      = ...` is an external side effect with no business re-running on
///      every retry attempt.
///   2. Nothing changes its `ValueNotifier<int>` type, but it's worth
///      knowing: `ValueNotifier` only notifies listeners when the new value
///      *differs* from the old one. Two consecutive quests that each earn
///      the same star count (3 stars, then 3 stars again) will only fire the
///      Victory Screen listener the first time. Fixing that properly means
///      changing the reactive primitive itself (e.g. a `Stream<int>` exposed
///      on the [GamificationRepository] interface, replacing the static
///      field) in lockstep with the Victory Screen's listener — flagged in
///      the review as a recommended follow-up rather than guessed at here.
class GamificationRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements GamificationRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  static final ValueNotifier<int> lastEarnedStars = ValueNotifier<int>(0);

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
    bool isVaultReward = false,
    int? starsEarned,
    int? addMagicStars,
    int? claimChestTier,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      // Derived purely from the starsEarned *parameter* — identical on every
      // transaction retry — so it's computed once, outside the closure.
      final int finalStarsEarned = starsEarned ?? 3;

      final result = await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        // Parse once via UserModel.fromMap instead of hand-rolling defensive
        // casts for each of the 7 fields this method touches — that parsing
        // already exists, is more defensive (e.g. it survives a Timestamp
        // stored as an ISO string), and is exercised everywhere else a user
        // document is read. Every collection below is a fresh, independent
        // copy, so mutating it can't leak into the UserModel's own internal
        // state or into a discarded retry attempt.
        final userData = UserModel.fromMap(doc.data()!);

        final dailyHistory = Map<String, int>.from(userData.dailyXpHistory);
        final activities = List<Map<String, dynamic>>.from(
          userData.recentActivities,
        );
        final completedLevels = userData.completedLevels.map(
          (k, v) => MapEntry(k, List<int>.from(v)),
        );
        final unlockedLevels = Map<String, int>.from(userData.unlockedLevels);
        final starRatings = userData.starRatings.map(
          (k, v) => MapEntry(k, Map<String, int>.from(v)),
        );
        var coinHistoryList = List<Map<String, dynamic>>.from(
          userData.coinHistory,
        );

        // ---- Replay detection ----
        final categoryCompleted = completedLevels[gameType] ?? <int>[];
        final bool isReplay = categoryCompleted.contains(level);

        // ---- XP multiplier calculation ----
        var xpMultiplier = 1.0;
        if (userData.hasPermanentXPBoost) {
          xpMultiplier *= UserGameConstants.kPermanentXpBoostMultiplier;
        }
        if (userData.isDoubleXPActive) {
          xpMultiplier *= UserGameConstants.kDoubleXpMultiplier;
        }

        final baseXp = isReplay
            ? (xpIncrease * UserGameConstants.kReplayXpFraction)
            : xpIncrease.toDouble();
        final finalXpIncrease = (baseXp * xpMultiplier).round();

        // ---- Completed & unlocked levels ----
        if (!isReplay && !isVaultReward) {
          categoryCompleted.add(level);
          completedLevels[gameType] = categoryCompleted;
        }

        final currentUnlocked = unlockedLevels[gameType] ?? 1;
        if (!isVaultReward && level >= currentUnlocked) {
          // Free levels (1-10) or Premium users automatically unlock the next level.
          // Otherwise, the user must explicitly purchase the next level via the Toll Gate.
          if (level < 10 || userData.isPremium) {
            unlockedLevels[gameType] = level + 1;
          }
        }

        final categoryStars = Map<String, int>.from(
          starRatings[gameType] ?? <String, int>{},
        );

        // 1. Update Gameplay Stars
        if (starsEarned != null) {
          final currentStars = categoryStars[level.toString()] ?? 0;
          if (finalStarsEarned > currentStars) {
            categoryStars[level.toString()] = finalStarsEarned;
          }
        }

        // 2. Add Magic Stars
        if (addMagicStars != null) {
          final currentMagicStars = categoryStars['magic_stars'] ?? 0;
          categoryStars['magic_stars'] = currentMagicStars + addMagicStars;
        }

        // 3. Update Claimed Chest Tier
        if (claimChestTier != null) {
          final currentClaimedTier = categoryStars['claimed_chests'] ?? 0;
          if (claimChestTier > currentClaimedTier) {
            categoryStars['claimed_chests'] = claimChestTier;
          }
        }

        starRatings[gameType] = categoryStars;

        // ---- Daily XP history ----
        final now = DateTime.now();
        final todayKey = _dateKey(now);
        dailyHistory[todayKey] =
            (dailyHistory[todayKey] ?? 0) + finalXpIncrease;
        _trimOldestDailyEntries(
          dailyHistory,
          UserGameConstants.kDailyXpHistoryLimit,
        );

        // ---- Recent activities ----
        // 'titleKey' is a stable lookup key (e.g. into ARB files), not
        // display text — the previous version baked a pre-formatted English
        // sentence ('Quest Completed', '+50 XP · +20 Coins') directly into
        // Firestore, which can never be localized for any of this app's
        // other 17 target languages no matter what the UI does with it
        // afterwards. xpEarned/coinsEarned are now separate numeric fields
        // so the presentation layer can run them through its own
        // number-formatting and pluralization rules per-locale.
        activities.insert(0, <String, dynamic>{
          'titleKey': 'activity.quest_completed',
          'gameType': gameType,
          'xpEarned': finalXpIncrease,
          'coinsEarned': coinIncrease,
          'timestamp': Timestamp.now(),
          'type': 'quest',
        });
        final trimmedActivities =
            activities.length > UserGameConstants.kActivityHistoryLimit
            ? activities.sublist(0, UserGameConstants.kActivityHistoryLimit)
            : activities;

        // ---- Coin reward calculation ----
        // Kids Zone games route to kidsCoins; other games route to coins.
        final isKidsGame = UserGameConstants.kKidsGameTypes.contains(gameType);

        var finalCoinIncrease = (!isVaultReward && isReplay && !isDoubleReward)
            ? 0
            : coinIncrease;
        if (!isReplay && (userData.isPremium || userData.level >= 100)) {
          finalCoinIncrease = coinIncrease * 2;
        }

        // ---- Coin history ----
        // 'coin_history.quest_reward' is a stable key, not English text — see
        // the recentActivities comment above for why. gameType travels
        // alongside it as a separate param for the presentation layer to
        // interpolate however each locale's grammar requires.
        coinHistoryList = _recordCoinHistory(
          coinHistoryList,
          titleKey: 'coin_history.quest_reward',
          amount: finalCoinIncrease,
          isEarned: true,
          params: {'gameType': gameType},
        );

        // ---- Atomic update ----
        transaction.update(docRef, {
          'totalExp': userData.totalExp + finalXpIncrease,
          (isKidsGame ? 'kidsCoins' : 'coins'): FieldValue.increment(
            finalCoinIncrease,
          ),
          'coinHistory': coinHistoryList,
          'dailyXpHistory': dailyHistory,
          'recentActivities': trimmedActivities,
          'completedLevels': completedLevels,
          'unlockedLevels': unlockedLevels,
          'starRatings': starRatings,
        });

        return const Right<Failure, void>(null);
      });

      // Fire the reactive stars notifier only once the transaction has
      // actually committed (see class doc for why this can't live inside
      // the transaction closure above).
      if (result.isRight() && starsEarned != null) {
        lastEarnedStars.value = finalStarsEarned;
      }

      return result;
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final unlockedLevels = (doc.exists && doc.data() != null)
            ? _parseIntMap(doc.data()!['unlockedLevels'])
            : <String, int>{};

        final currentUnlocked = unlockedLevels[categoryId] ?? 1;
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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final currentStats = (doc.exists && doc.data() != null)
            ? _parseIntMap(doc.data()!['categoryStats'])
            : <String, int>{};

        final currentScore =
            currentStats[categoryId] ?? UserGameConstants.kCategoryStatDefault;
        final delta = isCorrect
            ? UserGameConstants.kCategoryStatStep
            : -UserGameConstants.kCategoryStatStep;
        // num.clamp(num, num) returns num even when called on an int with
        // int bounds — assigning it straight back to an int-typed map value
        // (as the original code did) is a static type error. .toInt() makes
        // the narrowing explicit.
        final newScore = (currentScore + delta)
            .clamp(
              UserGameConstants.kCategoryStatMin,
              UserGameConstants.kCategoryStatMax,
            )
            .toInt();

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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

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
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = snapshot.data()!;
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) {
          _log(
            'GamificationRepository: repairStreak rejected — insufficient coins.',
          );
          return Left(AuthFailure('insufficient-coins'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.repaired_streak',
          amount: -cost,
          isEarned: false,
        );

        final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
        // Repairing a broken streak always sets it to at least 2 so the
        // UI shows a meaningful restored value, even when the streak was 0 or 1.
        final newStreak = currentStreak <= 1 ? 2 : currentStreak + 1;

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'coinHistory': history,
          'currentStreak': newStreak,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // repairStreakFree
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> repairStreakFree() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      // Same restoration formula as repairStreak, minus the balance check
      // and deduction — this is the "watch an ad instead of paying" variant.
      // Still transactional: the read of currentStreak must be consistent
      // with the write, or two near-simultaneous calls (e.g. two sessions
      // on the same account) could both read the same stale value and one
      // increment would be lost. Replaces
      // ProgressionBloc._onRepairStreakWithAd's previous client-side
      // read-then-write via a generic UpdateUser call.
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final currentStreak =
            (snapshot.data()!['currentStreak'] as num?)?.toInt() ?? 0;
        final newStreak = currentStreak <= 1 ? 2 : currentStreak + 1;

        transaction.update(docRef, {'currentStreak': newStreak});
        return const Right<Failure, void>(null);
      });
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
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.purchased_streak_freeze',
          amount: -cost,
          isEarned: false,
        );

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'streakFreezes': FieldValue.increment(1),
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
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
        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.purchased_double_xp',
          amount: -cost,
          isEarned: false,
        );

        final expiry = DateTime.now().add(const Duration(hours: 24));
        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'doubleXP': 1,
          'doubleXPExpiry': Timestamp.fromDate(expiry),
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // purchasePermanentXPBoost
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> purchasePermanentXPBoost(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);
      // Replaces ProgressionBloc._onPurchasePermanentXPBoost's previous
      // client-side read-then-write via a generic UpdateUser call (flagged
      // in that method's own doc comment as needing exactly this).
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = doc.data()!;
        // Idempotent: silently succeed (no charge) if already active.
        if (data['hasPermanentXPBoost'] == true) {
          return const Right<Failure, void>(null);
        }

        final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < cost) {
          return Left(AuthFailure('insufficient-coins'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.purchased_permanent_xp_boost',
          amount: -cost,
          isEarned: false,
        );

        transaction.update(docRef, {
          'coins': currentCoins - cost,
          'hasPermanentXPBoost': true,
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
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
    bool isKidsMode = false,
  }) async {
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
        // isKidsMode is intentionally not consulted here: Golden Keys are a
        // single universal currency (purchaseGoldenKey always credits `keys`
        // regardless of isKidsMode — see its interface doc), so there's no
        // separate kids-mode balance to branch on for this purchase either.
        final currentKeys = (data['keys'] as num?)?.toInt() ?? 0;
        if (currentKeys < cost) {
          return Left(AuthFailure('insufficient-golden-keys'));
        }

        final unlockedLevels = _parseIntMap(data['unlockedLevels']);
        final currentUnlocked = unlockedLevels[gameType] ?? 1;
        unlockedLevels[gameType] = currentUnlocked + 3;

        transaction.update(docRef, {
          'keys': currentKeys - cost,
          'unlockedLevels': unlockedLevels,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // purchaseGoldenKey
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> purchaseGoldenKey({
    required int cost,
    required bool isKidsMode,
  }) async {
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
        final currentKeys = (data['keys'] as num?)?.toInt() ?? 0;

        if (isKidsMode) {
          final currentKidsCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
          if (currentKidsCoins < cost) {
            return Left(AuthFailure('insufficient-kids-coins'));
          }
          transaction.update(docRef, {
            'kidsCoins': currentKidsCoins - cost,
            'keys': currentKeys + 1,
          });
        } else {
          final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) {
            return Left(AuthFailure('insufficient-coins'));
          }
          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'keys': currentKeys + 1,
          });
        }
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // addGoldenKey
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> addGoldenKey({required int amount}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      // Pure additive credit with no balance-sufficiency check to enforce,
      // so FieldValue.increment alone is atomic and correct server-side —
      // no read-modify-write transaction (and its retry round trips) needed.
      await _firestore.collection('users').doc(user.uid).update({
        'keys': FieldValue.increment(amount),
      });
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimStreakMilestone
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> claimStreakMilestone({
    required int milestone,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      // The reward is looked up here, server-side, from a fixed table — it
      // is never accepted as a parameter. Combined with the
      // already-claimed check below, this closes the vulnerability in the
      // previous client-side implementation (ProgressionBloc's
      // _onClaimStreakMilestone), which trusted a `reward` value carried
      // straight through from the triggering event with no check that the
      // milestone hadn't already been paid out — a double-tap, or a client
      // dispatching the event directly with an arbitrary milestone/reward
      // pair, could mint unlimited coins.
      final reward = UserGameConstants.kStreakMilestoneRewards[milestone];
      if (reward == null) {
        return Left(AuthFailure('unrecognized-milestone'));
      }

      final docRef = _firestore.collection('users').doc(user.uid);
      return await _firestore.runTransaction<Either<Failure, void>>((
        transaction,
      ) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(ServerFailure('user-data-not-found'));
        }

        final data = doc.data()!;
        final claimed = _parseIntList(data['claimedStreakMilestones']);
        if (claimed.contains(milestone)) {
          return Left(AuthFailure('milestone-already-claimed'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.streak_milestone_reward',
          amount: reward,
          isEarned: true,
          params: {'milestone': milestone},
        );

        transaction.update(docRef, {
          'coins': FieldValue.increment(reward),
          'claimedStreakMilestones': FieldValue.arrayUnion([milestone]),
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimLevelMilestone
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> claimLevelMilestone({
    required int milestone,
    required int reward,
  }) async {
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
        final claimed = _parseIntList(data['claimedLevelMilestones']);
        if (claimed.contains(milestone)) {
          return Left(AuthFailure('milestone-already-claimed'));
        }

        // No server-side level-milestone reward table exists in this
        // feature slice (see this method's interface doc), so `reward`
        // is still trusted from the caller — this check is the part that
        // *can* be validated without one: a milestone can't be claimed
        // for a level the user hasn't actually reached yet, computed from
        // totalExp server-side rather than accepted as a parameter.
        final totalExp = (data['totalExp'] as num?)?.toInt() ?? 0;
        final currentLevel =
            (totalExp / UserGameConstants.kXpPerLevel).floor() + 1;
        if (milestone > currentLevel) {
          return Left(AuthFailure('milestone-not-yet-reached'));
        }

        final history = _recordCoinHistory(
          _parseMapList(data['coinHistory']),
          titleKey: 'coin_history.level_milestone_reward',
          amount: reward,
          isEarned: true,
          params: {'milestone': milestone},
        );

        transaction.update(docRef, {
          'coins': FieldValue.increment(reward),
          'claimedLevelMilestones': FieldValue.arrayUnion([milestone]),
          'coinHistory': history,
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses a Firestore map of {String → num} to {String → int} defensively.
  /// Local counterpart to the equivalent helper in UserModel — Dart's
  /// per-file privacy means that one can't be imported and reused directly,
  /// and a full UserModel.fromMap parse would be wasteful for the
  /// single-field hot paths that use this (updateUnlockedLevel,
  /// updateCategoryStats, purchaseLevelUnlock run on nearly every answer or
  /// purchase, and only ever need one field out of the ~48 on the document).
  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw == null) return <String, int>{};
    final map = raw as Map<Object?, Object?>;
    return map.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  /// Parses a Firestore list of integers defensively. Local counterpart to
  /// the equivalent helper in UserModel — see [_parseIntMap]'s doc for why
  /// this can't just import that one.
  static List<int> _parseIntList(dynamic raw) {
    if (raw == null) return <int>[];
    return (raw as List<dynamic>)
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();
  }

  /// Parses a Firestore list of history/activity entries defensively.
  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    return (raw as List<dynamic>)
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Prepends a coin-history entry and trims to the configured retention
  /// limit. Shared by every purchase/spend method that logs to coinHistory.
  ///
  /// [titleKey] is a stable lookup key (e.g. into ARB files), never English
  /// display text — see the class doc's localization note. [params] carries
  /// any values the presentation layer needs to interpolate into the
  /// localized string (e.g. a game type or milestone number); omit it for
  /// keys that need no interpolation.
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

  /// Formats a `YYYY-MM-DD` key for [dailyXpHistory] bucketing.
  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Removes the oldest entries (by sorted key) from [dailyHistory] in place
  /// until its length is at most [limit].
  static void _trimOldestDailyEntries(
    Map<String, int> dailyHistory,
    int limit,
  ) {
    if (dailyHistory.length <= limit) return;
    final sortedKeys = dailyHistory.keys.toList()..sort();
    final toRemove = sortedKeys.length - limit;
    for (var i = 0; i < toRemove; i++) {
      dailyHistory.remove(sortedKeys[i]);
    }
  }

  /// Debug-only log helper. Produces no output in release builds.
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
