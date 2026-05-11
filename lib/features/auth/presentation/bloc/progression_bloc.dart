import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/notification_service.dart';

// --- EVENTS ---
abstract class ProgressionEvent extends Equatable {
  const ProgressionEvent();
  @override
  List<Object?> get props => [];
}

class ProgressionRepairStreakRequested extends ProgressionEvent {
  final int cost;
  const ProgressionRepairStreakRequested(this.cost);
  @override
  List<Object?> get props => [cost];
}

class ProgressionRepairStreakWithAdRequested extends ProgressionEvent {
  const ProgressionRepairStreakWithAdRequested();
}

class ProgressionPurchaseStreakFreezeRequested extends ProgressionEvent {
  final int cost;
  const ProgressionPurchaseStreakFreezeRequested(this.cost);
  @override
  List<Object?> get props => [cost];
}

class ProgressionActivateDoubleXPRequested extends ProgressionEvent {
  final int cost;
  const ProgressionActivateDoubleXPRequested(this.cost);
  @override
  List<Object?> get props => [cost];
}

class ProgressionClaimStreakMilestoneRequested extends ProgressionEvent {
  final int milestone;
  final int reward;
  const ProgressionClaimStreakMilestoneRequested(this.milestone, this.reward);
  @override
  List<Object?> get props => [milestone, reward];
}

class ProgressionClaimLevelMilestoneRequested extends ProgressionEvent {
  final int milestone;
  final int reward;
  const ProgressionClaimLevelMilestoneRequested(this.milestone, this.reward);
  @override
  List<Object?> get props => [milestone, reward];
}

class ProgressionCheckDailyStreakRequested extends ProgressionEvent {
  const ProgressionCheckDailyStreakRequested();
}

class ProgressionAddXpRequested extends ProgressionEvent {
  final int amount;
  const ProgressionAddXpRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ProgressionPurchasePermanentXPBoostRequested extends ProgressionEvent {
  final int cost;
  const ProgressionPurchasePermanentXPBoostRequested(this.cost);
  @override
  List<Object?> get props => [cost];
}

class ProgressionClearMessageRequested extends ProgressionEvent {
  const ProgressionClearMessageRequested();
}

// --- STATE ---
class ProgressionState extends Equatable {
  final String? message;
  final bool isLoading;
  final bool streakUpdatedToday;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;
  
  const ProgressionState({
    this.message, 
    this.isLoading = false,
    this.streakUpdatedToday = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
  });

  @override
  List<Object?> get props => [message, isLoading, streakUpdatedToday, lastPurchaseType, lastPurchaseSuccess];

  ProgressionState copyWith({
    String? message, 
    bool? isLoading,
    bool? streakUpdatedToday,
    String? lastPurchaseType,
    bool? lastPurchaseSuccess,
  }) {
    return ProgressionState(
      message: message,
      isLoading: isLoading ?? this.isLoading,
      streakUpdatedToday: streakUpdatedToday ?? this.streakUpdatedToday,
      lastPurchaseType: lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess,
    );
  }
}

// --- BLOC ---
class ProgressionBloc extends Bloc<ProgressionEvent, ProgressionState> {
  final RepairStreak repairStreak;
  final PurchaseStreakFreeze purchaseStreakFreeze;
  final ActivateDoubleXP activateDoubleXP;
  final UpdateUser updateUser;
  final AuthBloc authBloc;
  final NotificationService notificationService;

  // Track processing to avoid loops
  UserEntity? _lastProcessedUser;

  ProgressionBloc({
    required this.repairStreak,
    required this.purchaseStreakFreeze,
    required this.activateDoubleXP,
    required this.updateUser,
    required this.authBloc,
    required this.notificationService,
  }) : super(const ProgressionState()) {
    on<ProgressionRepairStreakRequested>(_onRepairStreak);
    on<ProgressionRepairStreakWithAdRequested>(_onRepairStreakWithAd);
    on<ProgressionPurchaseStreakFreezeRequested>(_onPurchaseStreakFreeze);
    on<ProgressionActivateDoubleXPRequested>(_onActivateDoubleXP);
    on<ProgressionClaimStreakMilestoneRequested>(_onClaimStreakMilestone);
    on<ProgressionClaimLevelMilestoneRequested>(_onClaimLevelMilestone);
    on<ProgressionCheckDailyStreakRequested>(_onCheckDailyStreak);
    on<ProgressionAddXpRequested>(_onAddXp);
    on<ProgressionPurchasePermanentXPBoostRequested>(_onPurchasePermanentXPBoost);
    on<ProgressionClearMessageRequested>((event, emit) => emit(state.copyWith(message: null, lastPurchaseType: null, lastPurchaseSuccess: null)));
  }

  Future<void> _onCheckDailyStreak(ProgressionCheckDailyStreakRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null || _lastProcessedUser == user) return;
    _lastProcessedUser = user;

    final now = DateTime.now();
    final lastLogin = user.lastLoginDate;

    if (lastLogin != null) {
      final lastLoginDateOnly = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      final dayDifference = nowDateOnly.difference(lastLoginDateOnly).inDays;

      if (dayDifference == 0) {
        // Already logged in today
        notificationService.scheduleStreakReminder(user.currentStreak);
        return;
      }

      if (dayDifference == 1) {
        // Consecutive Day - Increment Streak
        UserEntity updatedUser = user.copyWith(
          currentStreak: user.currentStreak + 1,
          lastLoginDate: now,
        );

        // Milestone logic
        final milestones = {7: 100, 14: 250, 30: 500};
        final newStreak = updatedUser.currentStreak;
        if (milestones.containsKey(newStreak) && !updatedUser.claimedStreakMilestones.contains(newStreak)) {
           final reward = milestones[newStreak]!;
           updatedUser = updatedUser.copyWith(
              coins: updatedUser.coins + reward,
              claimedStreakMilestones: [...updatedUser.claimedStreakMilestones, newStreak],
           );
        }

        final result = await updateUser(UpdateUserParams(user: updatedUser));
        result.fold(
          (failure) => null, // Silently fail or retry
          (_) {
            notificationService.scheduleStreakReminder(updatedUser.currentStreak);
            emit(state.copyWith(streakUpdatedToday: true));
          },
        );
      } else if (dayDifference > 1) {
        // Lost streak - check for shield
        if (user.streakFreezes > 0 || user.level >= 50) {
          final updatedUser = user.copyWith(
            streakFreezes: user.level >= 50 ? user.streakFreezes : user.streakFreezes - 1,
            lastLoginDate: now,
          );
          await updateUser(UpdateUserParams(user: updatedUser));
          notificationService.scheduleStreakReminder(updatedUser.currentStreak);
        } else {
          // Reset streak
          final updatedUser = user.copyWith(
            currentStreak: 1,
            lastLoginDate: now,
          );
          await updateUser(UpdateUserParams(user: updatedUser));
          notificationService.scheduleStreakReminder(1);
        }
      }
    } else {
      // First login
      final updatedUser = user.copyWith(currentStreak: 1, lastLoginDate: now);
      await updateUser(UpdateUserParams(user: updatedUser));
      notificationService.scheduleStreakReminder(1);
    }
  }

  Future<void> _onRepairStreak(ProgressionRepairStreakRequested event, Emitter<ProgressionState> emit) async {
    final result = await repairStreak(event.cost);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Streak Repaired!')),
    );
  }

  Future<void> _onRepairStreakWithAd(ProgressionRepairStreakWithAdRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;
    
    final newStreak = user.currentStreak == 1 ? 2 : user.currentStreak + 1;
    final updatedUser = user.copyWith(currentStreak: newStreak);
    
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Streak Repaired!')),
    );
  }

  Future<void> _onPurchaseStreakFreeze(ProgressionPurchaseStreakFreezeRequested event, Emitter<ProgressionState> emit) async {
    final result = await purchaseStreakFreeze(event.cost);
    result.fold(
      (failure) => emit(state.copyWith(
        message: failure.message,
        lastPurchaseType: 'shield',
        lastPurchaseSuccess: false,
      )),
      (_) => emit(state.copyWith(
        message: 'Streak Shield Purchased!',
        lastPurchaseType: 'shield',
        lastPurchaseSuccess: true,
      )),
    );
  }

  Future<void> _onActivateDoubleXP(ProgressionActivateDoubleXPRequested event, Emitter<ProgressionState> emit) async {
    final result = await activateDoubleXP(event.cost);
    result.fold(
      (failure) => emit(state.copyWith(
        message: failure.message,
        lastPurchaseType: 'warp',
        lastPurchaseSuccess: false,
      )),
      (_) => emit(state.copyWith(
        message: 'Double XP Activated!',
        lastPurchaseType: 'warp',
        lastPurchaseSuccess: true,
      )),
    );
  }

  Future<void> _onPurchasePermanentXPBoost(ProgressionPurchasePermanentXPBoostRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;
    
    if (user.coins < event.cost) {
      emit(state.copyWith(
        message: 'Not enough coins!',
        lastPurchaseType: 'scroll',
        lastPurchaseSuccess: false,
      ));
      return;
    }
    
    final updatedUser = user.copyWith(
      coins: user.coins - event.cost,
      hasPermanentXPBoost: true,
    );
    
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(
        message: failure.message,
        lastPurchaseType: 'scroll',
        lastPurchaseSuccess: false,
      )),
      (_) => emit(state.copyWith(
        message: 'Golden Scroll Activated!',
        lastPurchaseType: 'scroll',
        lastPurchaseSuccess: true,
      )),
    );
  }

  Future<void> _onClaimStreakMilestone(ProgressionClaimStreakMilestoneRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;
    
    final updatedUser = user.copyWith(
      coins: user.coins + event.reward,
      claimedStreakMilestones: [...user.claimedStreakMilestones, event.milestone],
    );
    
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Milestone Claimed!')),
    );
  }

  Future<void> _onClaimLevelMilestone(ProgressionClaimLevelMilestoneRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;
    
    final updatedUser = user.copyWith(
      coins: user.coins + event.reward,
      claimedLevelMilestones: [...user.claimedLevelMilestones, event.milestone],
    );
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Milestone Claimed!')),
    );
  }

  Future<void> _onAddXp(ProgressionAddXpRequested event, Emitter<ProgressionState> emit) async {
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(totalExp: user.totalExp + event.amount);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => null,
    );
  }
}
