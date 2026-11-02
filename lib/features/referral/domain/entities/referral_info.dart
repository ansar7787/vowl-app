import 'package:flutter/foundation.dart';

/// Represents a player's standing in the Monthly Ambassador Cup.
@immutable
class AmbassadorLeaderboardItem {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int referralCount;
  final int rank;

  const AmbassadorLeaderboardItem({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.referralCount,
    required this.rank,
  });

  /// The prize tier earned based on final ranking.
  AmbassadorRewardTier get rewardTier {
    if (rank == 1) return AmbassadorRewardTier.gold;
    if (rank == 2) return AmbassadorRewardTier.silver;
    if (rank == 3) return AmbassadorRewardTier.bronze;
    if (rank <= 10) return AmbassadorRewardTier.topTen;
    return AmbassadorRewardTier.participant;
  }
}

/// Tiered reward definitions for the Monthly Ambassador Cup.
enum AmbassadorRewardTier {
  gold(vipDays: 30, coins: 0, title: '🥇 1st Place', prizeDescription: '1 Month Free VIP'),
  silver(vipDays: 7, coins: 0, title: '🥈 2nd Place', prizeDescription: '1 Week Free VIP'),
  bronze(vipDays: 3, coins: 500, title: '🥉 3rd Place', prizeDescription: '500 Coins + 3 Days VIP'),
  topTen(vipDays: 0, coins: 200, title: '🏅 Top 10', prizeDescription: '200 Coins'),
  participant(vipDays: 0, coins: 0, title: 'Ambassador', prizeDescription: 'Community Badge');

  final int vipDays;
  final int coins;
  final String title;
  final String prizeDescription;

  const AmbassadorRewardTier({
    required this.vipDays,
    required this.coins,
    required this.title,
    required this.prizeDescription,
  });
}

/// Result of attempting to claim an invite code.
@immutable
class ReferralClaimResult {
  final bool success;
  final String message;
  final int coinsAwarded;
  final int vipDaysAwarded;
  final String? referrerName;

  const ReferralClaimResult({
    required this.success,
    required this.message,
    this.coinsAwarded = 0,
    this.vipDaysAwarded = 0,
    this.referrerName,
  });

  factory ReferralClaimResult.success({
    required int coinsAwarded,
    required int vipDaysAwarded,
    required String referrerName,
  }) {
    return ReferralClaimResult(
      success: true,
      message: 'Invite code accepted! Enjoy $coinsAwarded coins and $vipDaysAwarded day VIP trial.',
      coinsAwarded: coinsAwarded,
      vipDaysAwarded: vipDaysAwarded,
      referrerName: referrerName,
    );
  }

  factory ReferralClaimResult.failure(String error) {
    return ReferralClaimResult(
      success: false,
      message: error,
    );
  }
}

/// Result of claiming a past month's Ambassador Cup podium prize.
@immutable
class AmbassadorRewardClaimResult {
  final bool success;
  final String message;
  final int rank;
  final int coinsAwarded;
  final int vipDaysAwarded;
  final String monthKey;

  const AmbassadorRewardClaimResult({
    required this.success,
    required this.message,
    this.rank = 0,
    this.coinsAwarded = 0,
    this.vipDaysAwarded = 0,
    this.monthKey = '',
  });

  factory AmbassadorRewardClaimResult.success({
    required int rank,
    required int coinsAwarded,
    required int vipDaysAwarded,
    required String monthKey,
  }) {
    return AmbassadorRewardClaimResult(
      success: true,
      message: 'Congratulations! You claimed your $monthKey Ambassador Cup reward: $coinsAwarded coins & $vipDaysAwarded VIP days!',
      rank: rank,
      coinsAwarded: coinsAwarded,
      vipDaysAwarded: vipDaysAwarded,
      monthKey: monthKey,
    );
  }

  factory AmbassadorRewardClaimResult.failure(String error) {
    return AmbassadorRewardClaimResult(
      success: false,
      message: error,
    );
  }
}

