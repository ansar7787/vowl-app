import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

/// Abstract repository defining the viral referral engine contract.
abstract class ReferralRepository {
  /// Retrieves existing referral code for [user] or deterministically generates
  /// and registers a unique code (e.g. `VOWL-7K9A`).
  Future<String> getOrCreateReferralCode(UserEntity user);

  /// Claims an invitation code [code] on behalf of [user].
  ///
  /// Enforces:
  /// - User cannot claim their own code.
  /// - User can only claim one referral code per lifetime.
  /// - Awards 100 coins + 1 Day VIP trial to [user].
  /// - Sets `referredBy` on [user] so the inviter is credited when [user] clears Level 1.
  Future<ReferralClaimResult> claimReferralCode({
    required String code,
    required UserEntity user,
  });

  /// Called when a user completes Level 1.
  ///
  /// Checks if the user was referred by someone and hasn't unlocked the
  /// referrer's reward yet. If so, increments referrer's `totalReferralsCount`
  /// and `monthlyReferralsCount`, awarding 100 coins + 1 Day VIP to referrer.
  Future<void> onFriendCompletedLevelOne({
    required String friendUserId,
    required String referrerCode,
  });

  /// Fetches top 10 ambassadors for the given month key (format 'YYYY-MM').
  /// Defaults to current month in UTC if null.
  Future<List<AmbassadorLeaderboardItem>> getMonthlyAmbassadorLeaderboard({
    String? monthKey,
  });

  /// Claims reward for the previous month's Ambassador Cup if [user] finished
  /// in the top 10 and has not claimed it yet.
  Future<AmbassadorRewardClaimResult> claimMonthlyAmbassadorReward({
    required UserEntity user,
  });

  /// Checks whether any referred friends have completed Level 1 since the last sync.
  /// If new conversions are found on the user's referral document, credits 100 coins
  /// and 1 Day VIP extension per friend, updates the user's document, and returns
  /// the number of newly credited referrals (0 if none).
  Future<int> syncAmbassadorRewards(UserEntity user);
}

