import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/referral/domain/repositories/referral_repository.dart';
import 'package:vowl/features/referral/presentation/bloc/referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  final ReferralRepository _repository;

  ReferralCubit({required ReferralRepository repository})
    : _repository = repository,
      super(const ReferralState());

  /// Initializes the referral hub: generates/fetches code, syncs any pending ambassador rewards, and loads active month cup leaderboard.
  Future<void> init(UserEntity user) async {
    emit(
      state.copyWith(
        isLoading: true,
        lifetimeReferrals: user.totalReferralsCount,
        monthlyReferrals: user.activeMonthlyReferralsCount,
      ),
    );

    try {
      final code = await _repository.getOrCreateReferralCode(user);
      final syncedCount = await _repository.syncAmbassadorRewards(user);
      final leaderboard = await _repository.getMonthlyAmbassadorLeaderboard();

      emit(
        state.copyWith(
          isLoading: false,
          referralCode: code,
          ambassadorLeaderboard: leaderboard,
          syncedAmbassadorRewardCount: syncedCount > 0 ? syncedCount : null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Copies the referral code to clipboard and temporarily marks [copiedToClipboard].
  Future<void> copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    emit(state.copyWith(copiedToClipboard: true));
    await Future.delayed(const Duration(seconds: 3));
    if (!isClosed) {
      emit(state.copyWith(copiedToClipboard: false));
    }
  }

  /// Native OS share sheet with standard viral ambassador copy.
  Future<void> shareCode(String code) async {
    final message =
        '🚀 Join me on Vowl to level up your English skills!\n'
        'Use my invite code $code to unlock 100 Bonus Coins + 1 Day VIP Trial immediately:\n'
        'https://vowl-acbc5.web.app/invite/$code';

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Claim 100 Coins & Free VIP Trial on Vowl!',
      ),
    );
  }

  /// Claims an entered invite code on behalf of the current user.
  Future<void> claimCode(String code, UserEntity user) async {
    emit(
      state.copyWith(isClaiming: true, claimError: null, claimSuccess: null),
    );

    final result = await _repository.claimReferralCode(code: code, user: user);

    if (result.success) {
      emit(state.copyWith(isClaiming: false, claimSuccess: result));
    } else {
      emit(state.copyWith(isClaiming: false, claimError: result.message));
    }
  }

  /// Claims prize for previous month's Ambassador Cup.
  Future<void> claimMonthlyCupReward(UserEntity user) async {
    emit(state.copyWith(isClaimingCupReward: true));

    final result = await _repository.claimMonthlyAmbassadorReward(user: user);

    emit(
      state.copyWith(isClaimingCupReward: false, cupRewardClaimResult: result),
    );
  }
}
