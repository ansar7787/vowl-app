import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ============================================================================
// EVENTS
// ============================================================================

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

class ProgressionResetRequested extends ProgressionEvent {
  const ProgressionResetRequested();
}

// ============================================================================
// STATE
// ============================================================================

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

  ProgressionState copyWith({
    String? Function()? message,
    bool? isLoading,
    bool? streakUpdatedToday,
    String? Function()? lastPurchaseType,
    bool? Function()? lastPurchaseSuccess,
  }) {
    return ProgressionState(
      message: message != null ? message() : this.message,
      isLoading: isLoading ?? this.isLoading,
      streakUpdatedToday: streakUpdatedToday ?? this.streakUpdatedToday,
      lastPurchaseType: lastPurchaseType != null
          ? lastPurchaseType()
          : this.lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess != null
          ? lastPurchaseSuccess()
          : this.lastPurchaseSuccess,
    );
  }

  @override
  List<Object?> get props => [
    message,
    isLoading,
    streakUpdatedToday,
    lastPurchaseType,
    lastPurchaseSuccess,
  ];
}

// ============================================================================
// BLOC
// ============================================================================

class ProgressionBloc extends Bloc<ProgressionEvent, ProgressionState> {
  final RepairStreak repairStreak;
  final PurchaseStreakFreeze purchaseStreakFreeze;
  final ActivateDoubleXP activateDoubleXP;
  final UpdateUser updateUser;
  final AuthBloc authBloc;
  final NotificationService notificationService;

  // Prevents reprocessing the same [UserEntity] snapshot when the stream
  // fires multiple times with identical data. Relies on [UserEntity.operator==]
  // which performs deep equality across all fields.
  UserEntity? _lastProcessedUser;

  /// Streak milestone thresholds mapped to their coin rewards.
  static const Map<int, int> _streakMilestones = {7: 100, 14: 250, 30: 500};

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
    on<ProgressionPurchasePermanentXPBoostRequested>(
      _onPurchasePermanentXPBoost,
    );
    on<ProgressionClearMessageRequested>(
      (_, emit) => emit(
        state.copyWith(
          message: () => null,
          lastPurchaseType: () => null,
          lastPurchaseSuccess: () => null,
        ),
      ),
    );
    on<ProgressionResetRequested>(_onReset);
  }

  // ---------------------------------------------------------------------------
  // Guard
  // ---------------------------------------------------------------------------

  bool get _isAuthenticated =>
      authBloc.state.status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onCheckDailyStreak(
    ProgressionCheckDailyStreakRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null || _lastProcessedUser == user) return;
    _lastProcessedUser = user;

    final now = DateTime.now();
    final lastLogin = user.lastLoginDate;

    if (lastLogin == null) {
      // First-ever login
      final updatedUser = user.copyWith(currentStreak: 1, lastLoginDate: now);
      await updateUser(UpdateUserParams(user: updatedUser));
      notificationService.scheduleStreakReminder(1);
      return;
    }

    final lastDateOnly = DateTime(
      lastLogin.year,
      lastLogin.month,
      lastLogin.day,
    );
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final dayDifference = nowDateOnly.difference(lastDateOnly).inDays;

    if (dayDifference == 0) {
      // Already processed today
      notificationService.scheduleStreakReminder(user.currentStreak);
      return;
    }

    if (dayDifference == 1) {
      // Consecutive day — increment streak
      UserEntity updatedUser = user.copyWith(
        currentStreak: user.currentStreak + 1,
        lastLoginDate: now,
      );

      // Auto-claim milestone if applicable
      final newStreak = updatedUser.currentStreak;
      final milestoneReward = _streakMilestones[newStreak];
      if (milestoneReward != null &&
          !updatedUser.claimedStreakMilestones.contains(newStreak)) {
        final newHistory = List<Map<String, dynamic>>.from(
          updatedUser.coinHistory,
        );
        newHistory.insert(0, {
          'title': 'Auto-Claimed Milestone ($newStreak Days)',
          'amount': milestoneReward,
          'isEarned': true,
          'date': now.toIso8601String(),
        });
        if (newHistory.length > UserGameConstants.kActivityHistoryLimit) {
          newHistory.length = UserGameConstants.kActivityHistoryLimit;
        }
        updatedUser = updatedUser.copyWith(
          coins: updatedUser.coins + milestoneReward,
          claimedStreakMilestones: [
            ...updatedUser.claimedStreakMilestones,
            newStreak,
          ],
          coinHistory: newHistory,
        );
      }

      final result = await updateUser(UpdateUserParams(user: updatedUser));
      if (result.isRight()) {
        notificationService.scheduleStreakReminder(updatedUser.currentStreak);
        emit(state.copyWith(streakUpdatedToday: true));
      }
    } else {
      // Missed day — check for streak protection
      final hasShield = user.streakFreezes > 0;
      final hasAutoShield = user.level >= 50;

      if (hasShield || hasAutoShield) {
        final updatedUser = user.copyWith(
          streakFreezes: hasAutoShield
              ? user.streakFreezes
              : user.streakFreezes - 1,
          lastLoginDate: now,
        );
        await updateUser(UpdateUserParams(user: updatedUser));
        notificationService.scheduleStreakReminder(updatedUser.currentStreak);
        emit(
          state.copyWith(
            streakUpdatedToday: true,
            message: () => hasAutoShield
                ? 'Elite Shield Protected Your Streak!'
                : 'Streak Shield Activated!',
          ),
        );
      } else {
        final updatedUser = user.copyWith(currentStreak: 1, lastLoginDate: now);
        await updateUser(UpdateUserParams(user: updatedUser));
        notificationService.scheduleStreakReminder(1);
        emit(
          state.copyWith(
            streakUpdatedToday: true,
            message: () => 'Streak Lost! Starting Fresh at 1.',
          ),
        );
      }
    }
  }

  Future<void> _onRepairStreak(
    ProgressionRepairStreakRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await repairStreak(event.cost);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => emit(state.copyWith(message: () => 'Streak Repaired!')),
    );
  }

  Future<void> _onRepairStreakWithAd(
    ProgressionRepairStreakWithAdRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final newStreak = user.currentStreak <= 1 ? 2 : user.currentStreak + 1;
    final updatedUser = user.copyWith(currentStreak: newStreak);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => emit(state.copyWith(message: () => 'Streak Repaired!')),
    );
  }

  Future<void> _onPurchaseStreakFreeze(
    ProgressionPurchaseStreakFreezeRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await purchaseStreakFreeze(event.cost);
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'shield',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          message: () => 'Streak Shield Purchased!',
          lastPurchaseType: () => 'shield',
          lastPurchaseSuccess: () => true,
        ),
      ),
    );
  }

  Future<void> _onActivateDoubleXP(
    ProgressionActivateDoubleXPRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await activateDoubleXP(event.cost);
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'warp',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          message: () => 'Double XP Activated!',
          lastPurchaseType: () => 'warp',
          lastPurchaseSuccess: () => true,
        ),
      ),
    );
  }

  /// ⚠️ Client-side coin deduction. Requires a dedicated
  /// `ShopRepository.buyPermanentXPBoost()` Firestore transaction for
  /// production-safe atomic operation.
  Future<void> _onPurchasePermanentXPBoost(
    ProgressionPurchasePermanentXPBoostRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    if (user.coins < event.cost) {
      emit(
        state.copyWith(
          message: () => 'Not enough coins!',
          lastPurchaseType: () => 'scroll',
          lastPurchaseSuccess: () => false,
        ),
      );
      return;
    }

    final newHistory = List<Map<String, dynamic>>.from(user.coinHistory);
    newHistory.insert(0, {
      'title': 'Purchased Golden Scroll',
      'amount': -event.cost,
      'isEarned': false,
      'date': DateTime.now().toIso8601String(),
    });
    if (newHistory.length > UserGameConstants.kActivityHistoryLimit) {
      newHistory.length = UserGameConstants.kActivityHistoryLimit;
    }

    final updatedUser = user.copyWith(
      coins: user.coins - event.cost,
      hasPermanentXPBoost: true,
      coinHistory: newHistory,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'scroll',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) => emit(
        state.copyWith(
          message: () => 'Golden Scroll Activated!',
          lastPurchaseType: () => 'scroll',
          lastPurchaseSuccess: () => true,
        ),
      ),
    );
  }

  /// ⚠️ Client-side coin award. Requires a dedicated Firestore transaction
  /// for production-safe atomic milestone claiming.
  Future<void> _onClaimStreakMilestone(
    ProgressionClaimStreakMilestoneRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final newHistory = List<Map<String, dynamic>>.from(user.coinHistory);
    newHistory.insert(0, {
      'title': 'Streak Milestone Reward',
      'amount': event.reward,
      'isEarned': true,
      'date': DateTime.now().toIso8601String(),
    });
    if (newHistory.length > UserGameConstants.kActivityHistoryLimit) {
      newHistory.length = UserGameConstants.kActivityHistoryLimit;
    }

    final updatedUser = user.copyWith(
      coins: user.coins + event.reward,
      claimedStreakMilestones: [
        ...user.claimedStreakMilestones,
        event.milestone,
      ],
      coinHistory: newHistory,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => emit(state.copyWith(message: () => 'Milestone Claimed!')),
    );
  }

  Future<void> _onClaimLevelMilestone(
    ProgressionClaimLevelMilestoneRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final newHistory = List<Map<String, dynamic>>.from(user.coinHistory);
    newHistory.insert(0, {
      'title': 'Level Milestone Reward',
      'amount': event.reward,
      'isEarned': true,
      'date': DateTime.now().toIso8601String(),
    });
    if (newHistory.length > UserGameConstants.kActivityHistoryLimit) {
      newHistory.length = UserGameConstants.kActivityHistoryLimit;
    }

    final updatedUser = user.copyWith(
      coins: user.coins + event.reward,
      claimedLevelMilestones: [...user.claimedLevelMilestones, event.milestone],
      coinHistory: newHistory,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => emit(state.copyWith(message: () => 'Milestone Claimed!')),
    );
  }

  Future<void> _onAddXp(
    ProgressionAddXpRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(totalExp: user.totalExp + event.amount);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthRefreshUser()),
    );
  }

  void _onReset(
    ProgressionResetRequested event,
    Emitter<ProgressionState> emit,
  ) {
    _lastProcessedUser = null;
    emit(const ProgressionState());
  }
}
