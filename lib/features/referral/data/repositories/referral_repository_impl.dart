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

      // Calculate Smart VIP extension for invited friend: +1 Day VIP Trial
      final now = DateTime.now();
      final DateTime newExpiry;
      if (user.isPremium && user.premiumExpiryDate != null && user.premiumExpiryDate!.isAfter(now)) {
        newExpiry = user.premiumExpiryDate!.add(const Duration(days: 1));
      } else {
        newExpiry = now.add(const Duration(days: 1));
      }

      // Atomically update user's profile: +100 Coins, +1 Day VIP, mark claimed
      final userRef = _firestore.collection('users').doc(user.id);
      await userRef.update({
        'hasClaimedReferral': true,
        'referredBy': cleanCode,
        'coins': FieldValue.increment(100),
        'isPremium': true,
        'premiumExpiryDate': Timestamp.fromDate(newExpiry),
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
      }).timeout(_kNetworkTimeout);

      return ReferralClaimResult.success(
        coinsAwarded: 100,
        vipDaysAwarded: 1,
        referrerName: ownerName,
      );
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

      // Update the referral document
      final Map<String, dynamic> referralUpdates = {
        'successfulCount': FieldValue.increment(1),
      };

      if (storedMonth == currentMonth) {
        referralUpdates['monthlyCount'] = FieldValue.increment(1);
      } else {
        // New month rollover
        referralUpdates['monthlyCount'] = 1;
        referralUpdates['currentMonthKey'] = currentMonth;
      }

      await _firestore.collection('referrals').doc(cleanCode).update(referralUpdates);

      // Reward the ambassador: 100 Coins + 1 Day VIP
      final ambassadorUserDoc = await _firestore.collection('users').doc(ownerId).get().timeout(_kNetworkTimeout);
      if (ambassadorUserDoc.exists && ambassadorUserDoc.data() != null) {
        final ambData = ambassadorUserDoc.data()!;
        final now = DateTime.now();
        final rawExpiry = ambData['premiumExpiryDate'];
        DateTime? existingExpiry;
        if (rawExpiry is Timestamp) {
          existingExpiry = rawExpiry.toDate();
        }

        final bool isAlreadyVip = (ambData['isPremium'] as bool? ?? false) &&
            existingExpiry != null &&
            existingExpiry.isAfter(now);

        final DateTime newExpiry = isAlreadyVip
            ? existingExpiry.add(const Duration(days: 1))
            : now.add(const Duration(days: 1));

        final ambMonth = ambData['currentReferralMonthKey'] as String? ?? currentMonth;
        final bool isNewMonth = ambMonth != currentMonth;

        await _firestore.collection('users').doc(ownerId).update({
          'totalReferralsCount': FieldValue.increment(1),
          'monthlyReferralsCount': isNewMonth ? 1 : FieldValue.increment(1),
          'currentReferralMonthKey': currentMonth,
          'coins': FieldValue.increment(100),
          'isPremium': true,
          'premiumExpiryDate': Timestamp.fromDate(newExpiry),
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[ReferralRepositoryImpl] onFriendCompletedLevelOne error: $e');
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
          .limit(10)
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

      if (tier == AmbassadorRewardTier.participant) {
        return AmbassadorRewardClaimResult.failure('Ambassador rewards start at Top 10.');
      }

      final now = DateTime.now();
      final DateTime? newExpiry;
      if (tier.vipDays > 0) {
        if (user.isPremium && user.premiumExpiryDate != null && user.premiumExpiryDate!.isAfter(now)) {
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

