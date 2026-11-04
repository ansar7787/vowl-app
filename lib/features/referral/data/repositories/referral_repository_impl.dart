import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';

/// Production implementation of [ReferralRepository] running entirely on Firestore
/// with $0.00 infrastructure cost, robust network timeouts, and anti-loophole guards.
class ReferralRepositoryImpl implements ReferralRepository {
  final FirebaseFirestore _firestore;

  static const Duration _kNetworkTimeout = Duration(seconds: 10);

  ReferralRepositoryImpl([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static String _getCurrentMonthKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _getPreviousMonthKey([DateTime? date]) {
    final now = (date ?? DateTime.now()).toUtc();
    final prev = DateTime.utc(now.year, now.month - 1, 1);
    return '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
  }

  @override
  Future<String> getOrCreateReferralCode(UserEntity user) async {
    if (user.referralCode != null && user.referralCode!.trim().isNotEmpty) {
      return user.referralCode!.trim().toUpperCase();
    }

    try {
      final existingQuery = await _firestore
          .collection('referrals')
          .where('ownerId', isEqualTo: user.id)
          .limit(1)
          .get()
          .timeout(_kNetworkTimeout);

      if (existingQuery.docs.isNotEmpty) {
        final existingCode = existingQuery.docs.first.id.toUpperCase();
        // Sync back to user doc if missing
        await _firestore.collection('users').doc(user.id).update({
          'referralCode': existingCode,
        });
        return existingCode;
      }

      // Generate deterministic readable code: VOWL-XXXX (uppercase letters and digits)
      final cleanName = user.safeDisplayName
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
          .toUpperCase();
      final prefix = cleanName.length >= 3 ? cleanName.substring(0, 3) : 'VOW';
      final randomSuffix = (Random().nextInt(9000) + 1000).toString();
      final code = 'VOWL-$prefix$randomSuffix'.toUpperCase();

      final currentMonth = _getCurrentMonthKey();

      // Write to referrals registry
      await _firestore.collection('referrals').doc(code).set({
        'code': code,
        'ownerId': user.id,
        'ownerName': user.safeDisplayName,
        'ownerPhotoUrl': user.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'successfulCount': 0,
        'monthlyCount': 0,
        'currentMonthKey': currentMonth,
      }).timeout(_kNetworkTimeout);

      // Persist to user record
      await _firestore.collection('users').doc(user.id).update({
        'referralCode': code,
        'currentReferralMonthKey': currentMonth,
      }).timeout(_kNetworkTimeout);

      return code;
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] getOrCreateReferralCode error: $e');
      // Graceful offline fallback
      final fallback = 'VOWL-${user.id.substring(0, min(4, user.id.length)).toUpperCase()}';
      return fallback;
    }
  }

  List<Map<String, dynamic>> _recordCoinHistory(
    List<Map<String, dynamic>> existingHistory, {
    required String titleKey,
    required int amount,
    required bool isEarned,
  }) {
    final updated = List<Map<String, dynamic>>.from(existingHistory);
    updated.insert(0, {
      'amount': amount,
      'isEarned': isEarned,
      'titleKey': titleKey,
      'date': DateTime.now().toIso8601String(),
    });
    if (updated.length > 50) {
      return updated.sublist(0, 50);
    }
    return updated;
  }

  @override
  Future<ReferralClaimResult> claimReferralCode({
    required String code,
    required UserEntity user,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    if (cleanCode.isEmpty) {
      return ReferralClaimResult.failure('Please enter a valid referral code.');
    }

    if (user.hasClaimedReferral) {
      return ReferralClaimResult.failure('You have already claimed an invite bonus on this account.');
    }

    if (user.pendingReferralCode != null && user.pendingReferralCode!.toUpperCase() == cleanCode) {
      return ReferralClaimResult.failure('You already have this referral code pending! Complete Adventure Level 1 to activate.');
    }

    if (user.referralCode != null && user.referralCode!.toUpperCase() == cleanCode) {
      return ReferralClaimResult.failure('You cannot claim your own invite code.');
    }

    try {
      final docRef = _firestore.collection('referrals').doc(cleanCode);
      final snapshot = await docRef.get().timeout(_kNetworkTimeout);

      if (!snapshot.exists || snapshot.data() == null) {
        return ReferralClaimResult.failure('Invite code not found. Please double-check the code.');
      }

      final data = snapshot.data()!;
      final ownerId = data['ownerId'] as String?;
      final ownerName = (data['ownerName'] as String?) ?? 'A Vowl Ambassador';

      if (ownerId == user.id) {
        return ReferralClaimResult.failure('You cannot claim your own invite code.');
      }

      // Check whether user has already completed Adventure Level 1 in any category
      final hasCompletedLevelOne = user.completedLevels.values.any((levels) => levels.contains(1));

      if (hasCompletedLevelOne) {
        // Milestone already met: activate bonus immediately!
        final now = DateTime.now();
        final DateTime newExpiry;
        if (user.hasActivePremium && user.premiumExpiryDate != null) {
          newExpiry = user.premiumExpiryDate!.add(const Duration(days: 1));
        } else {
          newExpiry = now.add(const Duration(days: 1));
        }

        final userDoc = await _firestore.collection('users').doc(user.id).get().timeout(_kNetworkTimeout);
        final rawHistory = (userDoc.data()?['coinHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        final updatedHistory = _recordCoinHistory(
          rawHistory,
          titleKey: 'coin_history.referral_welcome',
          amount: 100,
          isEarned: true,
        );

        final userRef = _firestore.collection('users').doc(user.id);
        await userRef.update({
          'hasClaimedReferral': true,
          'referredBy': cleanCode,
          'pendingReferralCode': null,
          'coins': FieldValue.increment(100),
          'isPremium': true,
          'premiumExpiryDate': Timestamp.fromDate(newExpiry),
          'coinHistory': updatedHistory,
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
        }).timeout(_kNetworkTimeout);

        // Notify and reward the ambassador
        unawaited(onFriendCompletedLevelOne(
          friendUserId: user.id,
          referrerCode: cleanCode,
        ));

        return ReferralClaimResult.success(
          coinsAwarded: 100,
          vipDaysAwarded: 1,
          referrerName: ownerName,
        );
      } else {
        // Milestone not yet met: save pending code to activate upon Level 1 completion
        await _firestore.collection('users').doc(user.id).update({
          'pendingReferralCode': cleanCode,
          'referredBy': cleanCode,
        }).timeout(_kNetworkTimeout);

        return ReferralClaimResult.pending(
          referrerName: ownerName,
          message: 'Referral pass saved! Complete Adventure Level 1 to activate your 100 Bonus Coins & 1 Day VIP pass!',
        );
      }
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] claimReferralCode error: $e');
      return ReferralClaimResult.failure('Could not claim code. Please check your network and try again.');
    }
  }

  @override
  Future<void> onFriendCompletedLevelOne({
    required String friendUserId,
    required String referrerCode,
  }) async {
    final cleanCode = referrerCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return;

    try {
      final refDoc = await _firestore.collection('referrals').doc(cleanCode).get().timeout(_kNetworkTimeout);
      if (!refDoc.exists || refDoc.data() == null) return;

      final data = refDoc.data()!;
      final ownerId = data['ownerId'] as String?;
      if (ownerId == null || ownerId == friendUserId) return;

      final currentMonth = _getCurrentMonthKey();
      final storedMonth = data['currentMonthKey'] as String? ?? currentMonth;

      // Update the referral document atomically
      final Map<String, dynamic> referralUpdates = {
        'successfulCount': FieldValue.increment(1),
        'lastReferralTimestamp': FieldValue.serverTimestamp(),
      };

      if (storedMonth == currentMonth) {
        referralUpdates['monthlyCount'] = FieldValue.increment(1);
      } else {
        // New month rollover
        referralUpdates['monthlyCount'] = 1;
        referralUpdates['currentMonthKey'] = currentMonth;
      }

      await _firestore.collection('referrals').doc(cleanCode).update(referralUpdates);
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] onFriendCompletedLevelOne error: $e');
    }
  }

  @override
  Future<int> syncAmbassadorRewards(UserEntity user) async {
    final code = user.referralCode?.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      return 0;
    }

    try {
      final refDoc = await _firestore.collection('referrals').doc(code).get().timeout(_kNetworkTimeout);
      if (!refDoc.exists || refDoc.data() == null) {
        return 0;
      }

      final data = refDoc.data()!;
      final successfulCount = (data['successfulCount'] as num?)?.toInt() ?? 0;
      final monthlyCount = (data['monthlyCount'] as num?)?.toInt() ?? 0;
      final currentMonth = (data['currentMonthKey'] as String?) ?? _getCurrentMonthKey();

      final pendingDiff = successfulCount - user.totalReferralsCount;
      if (pendingDiff <= 0) {
        return 0;
      }

      final now = DateTime.now();
      final DateTime newExpiry;
      if (user.hasActivePremium && user.premiumExpiryDate != null) {
        newExpiry = user.premiumExpiryDate!.add(Duration(days: pendingDiff));
      } else {
        newExpiry = now.add(Duration(days: pendingDiff));
      }

      final userDoc = await _firestore.collection('users').doc(user.id).get().timeout(_kNetworkTimeout);
      var rawHistory = (userDoc.data()?['coinHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final coinsEarned = pendingDiff * 100;
      for (var i = 0; i < pendingDiff; i++) {
        rawHistory = _recordCoinHistory(
          rawHistory,
          titleKey: 'coin_history.referral_reward',
          amount: 100,
          isEarned: true,
        );
      }

      await _firestore.collection('users').doc(user.id).update({
        'totalReferralsCount': successfulCount,
        'monthlyReferralsCount': monthlyCount,
        'currentReferralMonthKey': currentMonth,
        'coins': FieldValue.increment(coinsEarned),
        'isPremium': true,
        'premiumExpiryDate': Timestamp.fromDate(newExpiry),
        'coinHistory': rawHistory,
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
      }).timeout(_kNetworkTimeout);

      return pendingDiff;
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] syncAmbassadorRewards error: $e');
      return 0;
    }
  }

  @override
  Future<List<AmbassadorLeaderboardItem>> getMonthlyAmbassadorLeaderboard({
    String? monthKey,
  }) async {
    final effectiveMonth = monthKey ?? _getCurrentMonthKey();

    try {
      final querySnapshot = await _firestore
          .collection('referrals')
          .where('currentMonthKey', isEqualTo: effectiveMonth)
          .orderBy('monthlyCount', descending: true)
          .limit(50)
          .get()
          .timeout(_kNetworkTimeout);

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final items = <AmbassadorLeaderboardItem>[];
      for (var i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        items.add(
          AmbassadorLeaderboardItem(
            userId: data['ownerId'] as String? ?? doc.id,
            displayName: (data['ownerName'] as String?)?.isNotEmpty == true
                ? data['ownerName'] as String
                : 'Vowl Ambassador',
            photoUrl: data['ownerPhotoUrl'] as String?,
            referralCount: (data['monthlyCount'] as num?)?.toInt() ?? 0,
            rank: i + 1,
          ),
        );
      }
      return items;
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] getMonthlyAmbassadorLeaderboard error: $e');
      return [];
    }
  }

  @override
  Future<AmbassadorRewardClaimResult> claimMonthlyAmbassadorReward({
    required UserEntity user,
  }) async {
    final prevMonthKey = _getPreviousMonthKey();

    if (user.claimedAmbassadorRewardMonthKeys.contains(prevMonthKey)) {
      return AmbassadorRewardClaimResult.failure('You have already claimed your Ambassador Cup reward for $prevMonthKey.');
    }

    try {
      final leaderboard = await getMonthlyAmbassadorLeaderboard(monthKey: prevMonthKey);
      final myEntryIndex = leaderboard.indexWhere((item) => item.userId == user.id);

      if (myEntryIndex == -1) {
        return AmbassadorRewardClaimResult.failure('You did not place in the top 10 for $prevMonthKey.');
      }

      final entry = leaderboard[myEntryIndex];
      final rank = entry.rank;
      final tier = entry.rewardTier;

      if (entry.referralCount < 1 ||
          tier == AmbassadorRewardTier.none ||
          tier == AmbassadorRewardTier.participant) {
        return AmbassadorRewardClaimResult.failure('Ambassador Cup rewards require at least 1 referral.');
      }

      final now = DateTime.now();
      final DateTime? newExpiry;
      if (tier.vipDays > 0) {
        if (user.hasActivePremium && user.premiumExpiryDate != null) {
          newExpiry = user.premiumExpiryDate!.add(Duration(days: tier.vipDays));
        } else {
          newExpiry = now.add(Duration(days: tier.vipDays));
        }
      } else {
        newExpiry = null;
      }

      final updatedClaimedKeys = [...user.claimedAmbassadorRewardMonthKeys, prevMonthKey];

      final Map<String, dynamic> updates = {
        'claimedAmbassadorRewardMonthKeys': updatedClaimedKeys,
        if (tier.coins > 0) 'coins': FieldValue.increment(tier.coins),
        if (tier.vipDays > 0) ...{
          'isPremium': true,
          'premiumExpiryDate': Timestamp.fromDate(newExpiry!),
        },
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
      };

      if (tier.coins > 0) {
        final userDoc = await _firestore.collection('users').doc(user.id).get().timeout(_kNetworkTimeout);
        final rawHistory = (userDoc.data()?['coinHistory'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        updates['coinHistory'] = _recordCoinHistory(
          rawHistory,
          titleKey: 'coin_history.ambassador_cup_reward',
          amount: tier.coins,
          isEarned: true,
        );
      }

      await _firestore.collection('users').doc(user.id).update(updates).timeout(_kNetworkTimeout);

      return AmbassadorRewardClaimResult.success(
        rank: rank,
        coinsAwarded: tier.coins,
        vipDaysAwarded: tier.vipDays,
        monthKey: prevMonthKey,
      );
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] claimMonthlyAmbassadorReward error: $e');
      return AmbassadorRewardClaimResult.failure('Could not process month-end claim. Please try again.');
    }
  }
}

