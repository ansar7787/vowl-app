import 'package:flutter/foundation.dart';
import 'package:vowl/features/referral/domain/entities/referral_info.dart';

@immutable
class ReferralState {
  final bool isLoading;
  final String? referralCode;
  final List<AmbassadorLeaderboardItem> ambassadorLeaderboard;
  final bool isClaiming;
  final String? claimError;
  final ReferralClaimResult? claimSuccess;
  final AmbassadorRewardClaimResult? cupRewardClaimResult;
  final bool isClaimingCupReward;
  final int lifetimeReferrals;
  final int monthlyReferrals;
  final bool copiedToClipboard;
  final int? syncedAmbassadorRewardCount;

  const ReferralState({
    this.isLoading = false,
    this.referralCode,
    this.ambassadorLeaderboard = const [],
    this.isClaiming = false,
    this.claimError,
    this.claimSuccess,
    this.cupRewardClaimResult,
    this.isClaimingCupReward = false,
    this.lifetimeReferrals = 0,
    this.monthlyReferrals = 0,
    this.copiedToClipboard = false,
    this.syncedAmbassadorRewardCount,
  });

  ReferralState copyWith({
    bool? isLoading,
    String? referralCode,
    List<AmbassadorLeaderboardItem>? ambassadorLeaderboard,
    bool? isClaiming,
    String? claimError,
    ReferralClaimResult? claimSuccess,
    AmbassadorRewardClaimResult? cupRewardClaimResult,
    bool? isClaimingCupReward,
    int? lifetimeReferrals,
    int? monthlyReferrals,
    bool? copiedToClipboard,
    int? syncedAmbassadorRewardCount,
  }) {
    return ReferralState(
      isLoading: isLoading ?? this.isLoading,
      referralCode: referralCode ?? this.referralCode,
      ambassadorLeaderboard:
          ambassadorLeaderboard ?? this.ambassadorLeaderboard,
      isClaiming: isClaiming ?? this.isClaiming,
      claimError: claimError,
      claimSuccess: claimSuccess,
      cupRewardClaimResult: cupRewardClaimResult,
      isClaimingCupReward: isClaimingCupReward ?? this.isClaimingCupReward,
      lifetimeReferrals: lifetimeReferrals ?? this.lifetimeReferrals,
      monthlyReferrals: monthlyReferrals ?? this.monthlyReferrals,
      copiedToClipboard: copiedToClipboard ?? this.copiedToClipboard,
      syncedAmbassadorRewardCount: syncedAmbassadorRewardCount,
    );
  }
}
