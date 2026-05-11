import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';

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

// --- STATE ---
class EconomyState extends Equatable {
  final String? message;
  final bool isLoading;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;
  
  const EconomyState({
    this.message, 
    this.isLoading = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
  });

  @override
  List<Object?> get props => [message, isLoading, lastPurchaseType, lastPurchaseSuccess];

  EconomyState copyWith({
    String? message, 
    bool? isLoading,
    String? lastPurchaseType,
    bool? lastPurchaseSuccess,
  }) {
    return EconomyState(
      message: message,
      isLoading: isLoading ?? this.isLoading,
      lastPurchaseType: lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess,
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
  final AuthBloc authBloc;

  EconomyBloc({
    required this.updateUserCoins,
    required this.purchaseHint,
    required this.claimVipGift,
    required this.claimDailyGift,
    required this.updateUser,
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
  }

  Future<void> _onAddCoins(EconomyAddCoinsRequested event, Emitter<EconomyState> emit) async {
    final result = await updateUserCoins(UpdateUserCoinsParams(
      amountChange: event.amount,
      title: event.title,
      isEarned: event.isEarned,
    ));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onAddKidsCoins(EconomyAddKidsCoinsRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(kidsCoins: user.kidsCoins + event.amount);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onPurchaseHint(EconomyPurchaseHintRequested event, Emitter<EconomyState> emit) async {
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
      (_) => emit(state.copyWith(
        lastPurchaseType: 'hint',
        lastPurchaseSuccess: true,
      )),
    );
  }

  Future<void> _onConsumeHint(EconomyConsumeHintRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null || user.hintCount <= 0) return;

    final updatedUser = user.copyWith(hintCount: user.hintCount - 1);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onClaimVipGift(EconomyClaimVipGiftRequested event, Emitter<EconomyState> emit) async {
    final result = await claimVipGift(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onClaimDailyGift(EconomyClaimDailyGiftRequested event, Emitter<EconomyState> emit) async {
    final result = await claimDailyGift(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onTripleUp(EconomyTripleUpRewardsRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      totalExp: user.totalExp + event.bonusXp,
      coins: user.coins + event.bonusCoins,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onClaimDailyChest(EconomyClaimDailyChestRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      coins: user.coins + event.amount,
      lastDailyRewardDate: DateTime.now(),
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }

  Future<void> _onClaimKidsDailyReward(EconomyClaimKidsDailyRewardRequested event, Emitter<EconomyState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(
      kidsCoins: user.kidsCoins + event.amount,
      lastKidsDailyRewardDate: DateTime.now(),
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }
}
