import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/claim_level_milestone.dart';
import 'package:vowl/features/auth/domain/usecases/claim_streak_milestone.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_permanent_xp_boost.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak_free.dart';
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

  /// Retained on the event for backwards API compatibility with existing
  /// call sites, but no longer used by the handler — see
  /// [ProgressionBloc._onClaimStreakMilestone]'s doc comment. The reward is
  /// now looked up server-side from `UserGameConstants.kStreakMilestoneRewards`
  /// rather than trusted from whatever dispatched this event.
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

/// ### Currency/reward safety — read this before touching a handler below
/// Several handlers here used to read balances/counters straight off the
/// (possibly stale) cached [AuthBloc] user, mutate them client-side, and
/// persist the result via a generic full-document [updateUser] write with
/// no Firestore transaction. Two of those (`_onClaimStreakMilestone`,
/// `_onClaimLevelMilestone`) had no check at all for whether the milestone
/// had *already* been claimed, and trusted a `reward` amount carried
/// straight through from the triggering event — a double-tap, or anything
/// dispatching the event directly, could mint coins with no bound. Every
/// handler below that could be safely rewired onto a transaction-backed,
/// server-validated repository method now is. [_onAddXp] could not be
/// (there's no dedicated backing method for a bare XP grant, and inventing
/// server-side validation for "how much XP is legitimate here" isn't a call
/// this review can make blind) — its doc comment explains why it's flagged
/// rather than changed.
class ProgressionBloc extends Bloc<ProgressionEvent, ProgressionState> {
  final RepairStreak repairStreak;
  final PurchaseStreakFreeze purchaseStreakFreeze;
  final ActivateDoubleXP activateDoubleXP;
  final UpdateUser updateUser;
  final AuthBloc authBloc;
  final NotificationService notificationService;

  // Added to replace unsafe client-side purchase/claim logic — see each
  // handler's doc comment below for what changed and why.
  final RepairStreakFree repairStreakFree;
  final PurchasePermanentXPBoost purchasePermanentXPBoost;
  final ClaimStreakMilestone claimStreakMilestone;
  final ClaimLevelMilestone claimLevelMilestone;

  // Prevents reprocessing the same [UserEntity] snapshot when the stream
  // fires multiple times with identical data. Relies on [UserEntity.operator==]
  // which performs deep equality across all fields.
  UserEntity? _lastProcessedUser;

  ProgressionBloc({
    required this.repairStreak,
    required this.purchaseStreakFreeze,
    required this.activateDoubleXP,
    required this.updateUser,
    required this.authBloc,
    required this.notificationService,
    required this.repairStreakFree,
    required this.purchasePermanentXPBoost,
    required this.claimStreakMilestone,
    required this.claimLevelMilestone,
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
      // Consecutive day — increment streak. The streak/lastLoginDate update
      // itself stays on the client-computed + updateUser path (unlike the
      // purchase/claim handlers below, this is a broad multi-field state
      // transition with shield/auto-shield branches — not a narrow,
      // template-able "spend X get Y" operation, so redesigning it into a
      // transaction isn't a safe change to make without much deeper
      // context on every edge case it needs to preserve).
      final updatedUser = user.copyWith(
        currentStreak: user.currentStreak + 1,
        lastLoginDate: now,
      );
      final newStreak = updatedUser.currentStreak;

      final result = await updateUser(UpdateUserParams(user: updatedUser));
      if (result.isRight()) {
        notificationService.scheduleStreakReminder(newStreak);
        emit(state.copyWith(streakUpdatedToday: true));

        // Milestone auto-claim now goes through the same atomic,
        // server-validated ClaimStreakMilestone use case as the
        // user-triggered claim flow, instead of being folded into the
        // updatedUser.copyWith(...) above. That previous version *did*
        // already check claimedStreakMilestones before crediting (so this
        // specific path was not the exploitable one — see class doc), but
        // it was still a non-transactional read-then-write, so a second
        // near-simultaneous trigger (e.g. two sessions) could still race.
        // The cheap local .contains check here just avoids a pointless
        // network round trip in the common case where the streak has
        // looped back through an already-claimed number after a reset.
        final isNewMilestone =
            UserGameConstants.kStreakMilestoneRewards.containsKey(newStreak) &&
            !user.claimedStreakMilestones.contains(newStreak);
        if (isNewMilestone) {
          await claimStreakMilestone(newStreak);
        }
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
                ? 'progression.elite_shield_protected'
                : 'progression.streak_shield_activated',
          ),
        );
      } else {
        final updatedUser = user.copyWith(currentStreak: 1, lastLoginDate: now);
        await updateUser(UpdateUserParams(user: updatedUser));
        notificationService.scheduleStreakReminder(1);
        emit(
          state.copyWith(
            streakUpdatedToday: true,
            message: () => 'progression.streak_lost_reset',
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
      (_) => emit(state.copyWith(message: () => 'progression.streak_repaired')),
    );
  }

  /// Repairs the streak with no coin cost via the transaction-safe
  /// [GamificationRepository.repairStreakFree] (the "watch an ad instead"
  /// variant of [_onRepairStreak]).
  ///
  /// Previously read `user.currentStreak` from the cached [AuthBloc] state,
  /// computed the same restoration formula
  /// [GamificationRepositoryImpl.repairStreak] already used server-side, and
  /// wrote it back via a generic `updateUser` call — duplicating
  /// server-side logic client-side with no transaction protecting the read.
  Future<void> _onRepairStreakWithAd(
    ProgressionRepairStreakWithAdRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await repairStreakFree(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) {
        emit(state.copyWith(message: () => 'progression.streak_repaired'));
        authBloc.add(const AuthRefreshUser());
      },
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
          message: () => 'progression.streak_shield_purchased',
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
          message: () => 'progression.double_xp_activated',
          lastPurchaseType: () => 'warp',
          lastPurchaseSuccess: () => true,
        ),
      ),
    );
  }

  /// Purchases the permanent XP boost via the transaction-safe
  /// [GamificationRepository.purchasePermanentXPBoost].
  ///
  /// Previously deducted [event.cost] from `coins` client-side and
  /// persisted the full user document with no transaction — this method's
  /// own doc comment previously flagged exactly that as needing "a
  /// dedicated `ShopRepository.buyPermanentXPBoost()` Firestore
  /// transaction", which now exists (on `GamificationRepository`, since
  /// `hasPermanentXPBoost` is a gamification field, not a shop one).
  Future<void> _onPurchasePermanentXPBoost(
    ProgressionPurchasePermanentXPBoostRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await purchasePermanentXPBoost(event.cost);
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'scroll',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthRefreshUser());
        emit(
          state.copyWith(
            message: () => 'progression.permanent_xp_boost_activated',
            lastPurchaseType: () => 'scroll',
            lastPurchaseSuccess: () => true,
          ),
        );
      },
    );
  }

  /// Claims the streak-milestone reward via the transaction-safe,
  /// server-validated [GamificationRepository.claimStreakMilestone].
  ///
  /// [event.reward] is deliberately **not** passed through — see that
  /// event field's own doc comment. Previously this handler credited
  /// `event.reward` coins and appended `event.milestone` to
  /// `claimedStreakMilestones` with **no check that it hadn't already been
  /// claimed**, via a generic `updateUser` write. A double-tap on the claim
  /// button, or anything dispatching this event directly, could claim the
  /// same milestone repeatedly for whatever reward amount it specified —
  /// this was the most severe issue found in this review.
  Future<void> _onClaimStreakMilestone(
    ProgressionClaimStreakMilestoneRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await claimStreakMilestone(event.milestone);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) {
        emit(state.copyWith(message: () => 'progression.milestone_claimed'));
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  /// Claims the level-milestone reward via
  /// [GamificationRepository.claimLevelMilestone].
  ///
  /// [event.reward] **is** still passed through here — see that method's
  /// doc comment for why the fix is only partial for level milestones (no
  /// server-side level-reward table exists anywhere in this feature slice
  /// to validate against, unlike streak milestones). What this closes:
  /// duplicate claims, and claims for a level the user hasn't reached —
  /// both of which this handler previously had zero protection against,
  /// identical to [_onClaimStreakMilestone]'s issue.
  Future<void> _onClaimLevelMilestone(
    ProgressionClaimLevelMilestoneRequested event,
    Emitter<ProgressionState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await claimLevelMilestone(
      ClaimLevelMilestoneParams(
        milestone: event.milestone,
        reward: event.reward,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) {
        emit(state.copyWith(message: () => 'progression.milestone_claimed'));
        authBloc.add(const AuthRefreshUser());
      },
    );
  }

  /// ⚠️ Not fixed — flagged. This is the same client-side,
  /// non-transactional, unvalidated-amount pattern as the handlers above
  /// (`user.totalExp + event.amount`, then a full-document `updateUser`
  /// write), and in principle a modified client could dispatch this event
  /// directly with an arbitrary `amount` to farm XP. It's left as-is rather
  /// than force-fixed because, unlike the milestone claims, there's no
  /// dedicated repository method backing a bare XP grant and no reference
  /// table this review has visibility into for what a legitimate `amount`
  /// should look like — inventing one blind risks being simply wrong. XP
  /// (unlike coins/keys) isn't directly spendable, which makes this lower
  /// severity than the fixes above, but not zero: `updateUserRewards`
  /// doubles coin rewards once a user's derived level (from `totalExp`)
  /// reaches 100, so unbounded XP inflation still has a downstream economic
  /// effect. Recommend a dedicated, bounded `GamificationRepository` method
  /// once the intended source/cap for bonus XP is decided.
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
