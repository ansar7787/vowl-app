import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_coins.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_chest.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_kids_daily_reward.dart';
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class EconomyEvent extends Equatable {
  const EconomyEvent();
  @override
  List<Object?> get props => [];
}

class EconomyAddCoinsRequested extends EconomyEvent {
  final int amount;
  final String title;
  final bool isEarned;
  // 'coin_history.earned_coins' is a stable lookup key, not English display
  // text — the previous default ('Earned Coins') was persisted verbatim
  // into Firestore's coinHistory and could never be localized for any
  // caller that didn't override it. See GamificationRepositoryImpl's class
  // doc for the full rationale; the same fix was applied there.
  const EconomyAddCoinsRequested(
    this.amount, {
    this.title = 'coin_history.earned_coins',
    this.isEarned = true,
  });
  @override
  List<Object?> get props => [amount, title, isEarned];
}

class EconomyAddKidsCoinsRequested extends EconomyEvent {
  final int amount;
  const EconomyAddKidsCoinsRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class EconomyPurchaseHintRequested extends EconomyEvent {
  final int cost;
  final int hintAmount;
  const EconomyPurchaseHintRequested(this.cost, {this.hintAmount = 1});
  @override
  List<Object?> get props => [cost, hintAmount];
}

class EconomyConsumeHintRequested extends EconomyEvent {
  const EconomyConsumeHintRequested();
}

class EconomyClaimVipGiftRequested extends EconomyEvent {
  const EconomyClaimVipGiftRequested();
}

class EconomyClaimDailyGiftRequested extends EconomyEvent {
  const EconomyClaimDailyGiftRequested();
}

class EconomyTripleUpRewardsRequested extends EconomyEvent {
  final int bonusXp;
  final int bonusCoins;
  const EconomyTripleUpRewardsRequested(this.bonusXp, this.bonusCoins);
  @override
  List<Object?> get props => [bonusXp, bonusCoins];
}

class EconomyClaimDailyChestRequested extends EconomyEvent {
  final int amount;
  const EconomyClaimDailyChestRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class EconomyClaimKidsDailyRewardRequested extends EconomyEvent {
  final int amount;
  const EconomyClaimKidsDailyRewardRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class EconomyAddBonusRewardsRequested extends EconomyEvent {
  final int bonusXp;
  final int bonusCoins;
  const EconomyAddBonusRewardsRequested({
    required this.bonusXp,
    required this.bonusCoins,
  });
  @override
  List<Object?> get props => [bonusXp, bonusCoins];
}

class EconomyCheckDailyRewardRequested extends EconomyEvent {
  const EconomyCheckDailyRewardRequested();
}

class EconomyResetRequested extends EconomyEvent {
  const EconomyResetRequested();
}

// ============================================================================
// STATE
// ============================================================================

class EconomyState extends Equatable {
  final String? message;
  final bool isLoading;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;
  final bool isDailyRewardAvailable;

  const EconomyState({
    this.message,
    this.isLoading = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
    this.isDailyRewardAvailable = false,
  });

  EconomyState copyWith({
    String? Function()? message,
    bool? isLoading,
    String? Function()? lastPurchaseType,
    bool? Function()? lastPurchaseSuccess,
    bool? isDailyRewardAvailable,
  }) {
    return EconomyState(
      message: message != null ? message() : this.message,
      isLoading: isLoading ?? this.isLoading,
      lastPurchaseType: lastPurchaseType != null
          ? lastPurchaseType()
          : this.lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess != null
          ? lastPurchaseSuccess()
          : this.lastPurchaseSuccess,
      isDailyRewardAvailable:
          isDailyRewardAvailable ?? this.isDailyRewardAvailable,
    );
  }

  @override
  List<Object?> get props => [
    message,
    isLoading,
    lastPurchaseType,
    lastPurchaseSuccess,
    isDailyRewardAvailable,
  ];
}

// ============================================================================
// BLOC
// ============================================================================

class EconomyBloc extends Bloc<EconomyEvent, EconomyState> {
  final UpdateUserCoins updateUserCoins;
  final PurchaseHint purchaseHint;
  final ClaimVipGift claimVipGift;
  final ClaimDailyGift claimDailyGift;
  final UpdateUser updateUser;
  final ClaimDailyChest claimDailyChest;
  final ClaimKidsDailyReward claimKidsDailyReward;
  final AwardKidsCoins awardKidsCoins;
  final UseHint useHint;

  /// [AuthBloc] is injected to read the current user and trigger profile
  /// refreshes after mutations. Note: this creates a BLoC-to-BLoC dependency.
  /// Prefer stream-based composition when the architecture is revisited.
  final AuthBloc authBloc;

  EconomyBloc({
    required this.updateUserCoins,
    required this.purchaseHint,
    required this.claimVipGift,
    required this.claimDailyGift,
    required this.updateUser,
    required this.claimDailyChest,
    required this.claimKidsDailyReward,
    required this.awardKidsCoins,
    required this.useHint,
    required this.authBloc,
  }) : super(const EconomyState()) {
    on<EconomyAddCoinsRequested>(_onAddCoins);
    on<EconomyAddKidsCoinsRequested>(_onAddKidsCoins);
    on<EconomyPurchaseHintRequested>(_onPurchaseHint);
    on<EconomyConsumeHintRequested>(_onConsumeHint);
    on<EconomyClaimVipGiftRequested>(_onClaimVipGift);
    on<EconomyClaimDailyGiftRequested>(_onClaimDailyGift);
    on<EconomyTripleUpRewardsRequested>(_onTripleUp);
    on<EconomyClaimKidsDailyRewardRequested>(_onClaimKidsDailyReward);
    on<EconomyClaimDailyChestRequested>(_onClaimDailyChest);
    on<EconomyAddBonusRewardsRequested>(_onAddBonusRewards);
    on<EconomyCheckDailyRewardRequested>(_onCheckDailyReward);
    on<EconomyResetRequested>(_onReset);
  }

  // ---------------------------------------------------------------------------
  // Guards
  // ---------------------------------------------------------------------------

  bool get _isAuthenticated =>
      authBloc.state.status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onAddCoins(
    EconomyAddCoinsRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    _log('EconomyBloc: Adding ${event.amount} coins…');

    final result = await updateUserCoins(
      UpdateUserCoinsParams(
        amountChange: event.amount,
        title: event.title,
        isEarned: event.isEarned,
      ),
    );
    result.fold(
      (failure) {
        _log('EconomyBloc: AddCoins FAILED: ${failure.message}');
        emit(state.copyWith(message: () => failure.message));
      },
      (_) {
        _log('EconomyBloc: AddCoins SUCCESS');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onAddKidsCoins(
    EconomyAddKidsCoinsRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await awardKidsCoins(event.amount);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthRefreshUser()),
    );
  }

  Future<void> _onPurchaseHint(
    EconomyPurchaseHintRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await purchaseHint(
      PurchaseHintParams(cost: event.cost, hintAmount: event.hintAmount),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'hint',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthRefreshUser());
        emit(
          state.copyWith(
            lastPurchaseType: () => 'hint',
            lastPurchaseSuccess: () => true,
          ),
        );
      },
    );
  }

  Future<void> _onConsumeHint(
    EconomyConsumeHintRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    _log('EconomyBloc: Consuming hint…');
    final result = await useHint(const NoParams());
    result.fold(
      (failure) {
        _log('EconomyBloc: Hint consumption FAILED: ${failure.message}');
        emit(state.copyWith(message: () => failure.message));
      },
      (_) {
        _log('EconomyBloc: Hint consumption SUCCESS');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimVipGift(
    EconomyClaimVipGiftRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await claimVipGift(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthRefreshUser()),
    );
  }

  Future<void> _onClaimDailyGift(
    EconomyClaimDailyGiftRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await claimDailyGift(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthRefreshUser()),
    );
  }

  /// Awards the ad-tripled coin bonus and optional XP via proper atomic
  /// paths that record a coinHistory ledger entry. The previous
  /// implementation used a raw [updateUser] full-document write, which
  /// bypassed [_recordCoinHistory] entirely — so the bonus coins were
  /// credited to the balance but never appeared in the Coin Ledger,
  /// leaving users confused about where their coins came from.
  Future<void> _onTripleUp(
    EconomyTripleUpRewardsRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    // ── Bonus coins: use the proper atomic path with coinHistory logging ──
    if (event.bonusCoins > 0) {
      final coinResult = await updateUserCoins(
        UpdateUserCoinsParams(
          amountChange: event.bonusCoins,
          title: 'coin_history.ad_triple_reward',
          isEarned: true,
        ),
      );
      coinResult.fold(
        (failure) {
          _log('EconomyBloc: TripleUp coins FAILED: ${failure.message}');
          emit(state.copyWith(message: () => failure.message));
        },
        (_) => _log('EconomyBloc: TripleUp coins SUCCESS (+${event.bonusCoins})'),
      );
    }

    // ── Bonus XP: still uses updateUser (no atomic XP-increment use case) ──
    if (event.bonusXp > 0) {
      final xpUser = authBloc.state.user;
      if (xpUser == null) return;
      final updatedUser = xpUser.copyWith(
        totalExp: xpUser.totalExp + event.bonusXp,
      );
      await updateUser(UpdateUserParams(user: updatedUser));
    }

    authBloc.add(const AuthRefreshUser());
  }

  /// ⚠️ Same caveat as [_onTripleUp] — see its doc comment.
  Future<void> _onAddBonusRewards(
    EconomyAddBonusRewardsRequested event,
    Emitter<EconomyState> emit,
  ) async {
    final user = authBloc.state.user;
    if (user == null) return;

    // ── Bonus coins: use the proper atomic path with coinHistory logging ──
    if (event.bonusCoins > 0) {
      final coinResult = await updateUserCoins(
        UpdateUserCoinsParams(
          amountChange: event.bonusCoins,
          title: 'coin_history.earned_coins',
          isEarned: true,
        ),
      );
      coinResult.fold(
        (failure) {
          _log('EconomyBloc: Bonus coins FAILED: ${failure.message}');
          emit(state.copyWith(message: () => failure.message));
        },
        (_) => _log('EconomyBloc: Bonus coins SUCCESS (+${event.bonusCoins})'),
      );
    }

    // ── Bonus XP: still uses updateUser (no atomic XP-increment use case) ──
    if (event.bonusXp > 0) {
      final xpUser = authBloc.state.user;
      if (xpUser == null) return;
      final updatedUser = xpUser.copyWith(
        totalExp: xpUser.totalExp + event.bonusXp,
      );
      await updateUser(UpdateUserParams(user: updatedUser));
    }

    authBloc.add(const AuthRefreshUser());
  }

  Future<void> _onClaimDailyChest(
    EconomyClaimDailyChestRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    _log('EconomyBloc: Claiming daily chest (${event.amount} coins)…');
    final result = await claimDailyChest(event.amount);
    result.fold(
      (failure) {
        _log('EconomyBloc: Daily chest FAILED: ${failure.message}');
        emit(state.copyWith(message: () => failure.message));
      },
      (_) {
        _log('EconomyBloc: Daily chest SUCCESS');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimKidsDailyReward(
    EconomyClaimKidsDailyRewardRequested event,
    Emitter<EconomyState> emit,
  ) async {
    if (!_isAuthenticated) return;
    _log('EconomyBloc: Claiming kids daily reward (${event.amount} coins)…');
    final result = await claimKidsDailyReward(event.amount);
    result.fold(
      (failure) {
        _log('EconomyBloc: Kids daily reward FAILED: ${failure.message}');
        emit(state.copyWith(message: () => failure.message));
      },
      (_) {
        _log('EconomyBloc: Kids daily reward SUCCESS');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onCheckDailyReward(
    EconomyCheckDailyRewardRequested event,
    Emitter<EconomyState> emit,
  ) async {
    final user = authBloc.state.user;
    if (user == null) {
      emit(state.copyWith(isDailyRewardAvailable: false));
      return;
    }

    final lastReward = user.lastDailyRewardDate;
    if (lastReward == null) {
      emit(state.copyWith(isDailyRewardAvailable: true));
      return;
    }

    final isSameDay = _isSameCalendarDay(lastReward, DateTime.now());
    emit(state.copyWith(isDailyRewardAvailable: !isSameDay));
  }

  void _onReset(EconomyResetRequested event, Emitter<EconomyState> emit) =>
      emit(const EconomyState());

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// True if [a] and [b] fall on the same calendar day (year/month/day) in
  /// local time. The same "already claimed today?" comparison this repeats
  /// exists independently in several repository implementations too (Dart's
  /// per-file privacy means none of them can share one helper) — see the
  /// review notes for the full list.
  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
