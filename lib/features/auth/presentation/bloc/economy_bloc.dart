import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_coins.dart';
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_chest.dart';
import 'package:vowl/features/auth/domain/usecases/claim_kids_daily_reward.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:flutter/foundation.dart';

// --- EVENTS ---
abstract class EconomyEvent extends Equatable {
  const EconomyEvent();
  @override
  List<Object?> get props => [];
}

class EconomyAddCoinsRequested extends EconomyEvent {
  final int amount;
  final String title;
  final bool isEarned;
  const EconomyAddCoinsRequested(this.amount, {this.title = 'Earned Coins', this.isEarned = true});
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
  const EconomyAddBonusRewardsRequested({required this.bonusXp, required this.bonusCoins});
  @override
  List<Object?> get props => [bonusXp, bonusCoins];
}

class EconomyCheckDailyRewardRequested extends EconomyEvent {
  const EconomyCheckDailyRewardRequested();
}

class EconomyResetRequested extends EconomyEvent {
  const EconomyResetRequested();
}

// --- STATE ---
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

  @override
  List<Object?> get props => [message, isLoading, lastPurchaseType, lastPurchaseSuccess, isDailyRewardAvailable];

  EconomyState copyWith({
    String? message, 
    bool? isLoading,
    String? lastPurchaseType,
    bool? lastPurchaseSuccess,
    bool? isDailyRewardAvailable,
  }) {
    return EconomyState(
      message: message,
      isLoading: isLoading ?? this.isLoading,
      lastPurchaseType: lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess,
      isDailyRewardAvailable: isDailyRewardAvailable ?? this.isDailyRewardAvailable,
    );
  }
}

// --- BLOC ---
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

  Future<void> _onAddCoins(EconomyAddCoinsRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    debugPrint('EconomyBloc: Adding Coins Atomic (${event.amount})...');
    final result = await updateUserCoins(UpdateUserCoinsParams(
      amountChange: event.amount,
      title: event.title,
      isEarned: event.isEarned,
    ));
    result.fold(
      (failure) {
        debugPrint('EconomyBloc: Adding Coins FAILED: ${failure.message}');
        emit(state.copyWith(message: failure.message));
      },
      (_) {
        debugPrint('EconomyBloc: Adding Coins SUCCESS. Refreshing User...');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onAddKidsCoins(EconomyAddKidsCoinsRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    final result = await awardKidsCoins(event.amount);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) {
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onPurchaseHint(EconomyPurchaseHintRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    final result = await purchaseHint(PurchaseHintParams(
      cost: event.cost,
      hintAmount: event.hintAmount,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        message: failure.message,
        lastPurchaseType: 'hint',
        lastPurchaseSuccess: false,
      )),
      (_) {
        authBloc.add(const AuthRefreshUser());
        emit(state.copyWith(
          lastPurchaseType: 'hint',
          lastPurchaseSuccess: true,
        ));
      },
    );
  }

  Future<void> _onConsumeHint(EconomyConsumeHintRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    debugPrint('EconomyBloc: Consuming Hint Atomic...');
    final result = await useHint(NoParams());
    result.fold(
      (failure) {
        debugPrint('EconomyBloc: Hint Consumption FAILED: ${failure.message}');
        emit(state.copyWith(message: failure.message));
      },
      (_) {
        debugPrint('EconomyBloc: Hint Consumption SUCCESS. Refreshing User...');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimVipGift(EconomyClaimVipGiftRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    final result = await claimVipGift(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) {
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimDailyGift(EconomyClaimDailyGiftRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    final result = await claimDailyGift(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) {
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onTripleUp(EconomyTripleUpRewardsRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      totalExp: user.totalExp + event.bonusXp,
      coins: user.coins + event.bonusCoins,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) {
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onAddBonusRewards(EconomyAddBonusRewardsRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      totalExp: user.totalExp + event.bonusXp,
      coins: user.coins + event.bonusCoins,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) {
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimDailyChest(EconomyClaimDailyChestRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    debugPrint('EconomyBloc: Claiming Daily Chest Atomic (${event.amount})...');
    final result = await claimDailyChest(event.amount);
    result.fold(
      (failure) {
        debugPrint('EconomyBloc: Daily Chest FAILED: ${failure.message}');
        emit(state.copyWith(message: failure.message));
      },
      (_) {
        debugPrint('EconomyBloc: Daily Chest SUCCESS. Refreshing User...');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onClaimKidsDailyReward(EconomyClaimKidsDailyRewardRequested event, Emitter<EconomyState> emit) async {
    if (authBloc.state.status != AuthStatus.authenticated) return;
    debugPrint('EconomyBloc: Claiming Kids Daily Reward Atomic (${event.amount})...');
    final result = await claimKidsDailyReward(event.amount);
    result.fold(
      (failure) {
        debugPrint('EconomyBloc: Kids Daily Reward FAILED: ${failure.message}');
        emit(state.copyWith(message: failure.message));
      },
      (_) {
        debugPrint('EconomyBloc: Kids Daily Reward SUCCESS. Refreshing User...');
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  Future<void> _onCheckDailyReward(EconomyCheckDailyRewardRequested event, Emitter<EconomyState> emit) async {
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

    final now = DateTime.now();
    final isSameDay = now.year == lastReward.year &&
        now.month == lastReward.month &&
        now.day == lastReward.day;

    emit(state.copyWith(isDailyRewardAvailable: !isSameDay));
  }

  void _onReset(EconomyResetRequested event, Emitter<EconomyState> emit) {
    emit(const EconomyState());
  }
}
