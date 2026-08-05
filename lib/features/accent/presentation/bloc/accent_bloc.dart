import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/get_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/preload_accent_quest.dart';
import 'package:vowl/features/accent/domain/usecases/clear_accent_quest_cache.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/core/network/network_info.dart';

import 'accent_event.dart';
import 'accent_state.dart';

// Re-export so callers that `import accent_bloc.dart` get everything.
export 'accent_event.dart';
export 'accent_state.dart';

// ---------------------------------------------------------------------------
// Callbacks — injected at construction for full testability and zero coupling
// to any specific analytics or crash-reporting SDK.
// ---------------------------------------------------------------------------

/// Called after significant game events (level start, complete, game-over).
/// Wire up Firebase Analytics, Amplitude, Posthog, etc. at the call-site.
typedef AccentAnalyticsCallback =
    void Function(String eventName, Map<String, Object?> params);

/// Called when an async operation fails (e.g. reward sync).
/// Wire up FirebaseCrashlytics.instance.recordError or Sentry.captureException.
///
/// Named [AccentErrorReporter] (not `onError`) to avoid shadowing
/// [BlocBase.onError] which is inherited from the BLoC framework.
typedef AccentErrorReporter =
    void Function(Object error, StackTrace stackTrace);

// ---------------------------------------------------------------------------
// AccentBloc
// ---------------------------------------------------------------------------

class AccentBloc extends Bloc<AccentEvent, AccentState> {
  final GetAccentQuest getQuest;
  final PreloadAccentQuest preloadQuest;
  final ClearAccentQuestCache clearCache;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  /// Optional: plug in your analytics SDK at the DI call-site.
  final AccentAnalyticsCallback? onAnalyticsEvent;

  /// Optional: plug in your crash reporter at the DI call-site.
  /// Named [errorReporter] (not `onError`) to avoid shadowing [BlocBase.onError].
  final AccentErrorReporter? errorReporter;

  // Stored to pass into reward calls after level completion.
  String? _currentGameType;
  int? _currentLevel;

  AccentBloc({
    required this.getQuest,
    required this.preloadQuest,
    required this.clearCache,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
    this.onAnalyticsEvent,
    this.errorReporter,
  }) : super(const AccentInitial()) {
    on<FetchAccentQuests>(_onFetch);
    on<PreloadBatch>(_onPreload);
    on<RetryCurrentQuestion>(_onRetry);
    on<SubmitAnswer>(_onSubmit);
    on<NextQuestion>(_onNext);
    on<AccentHintUsed>(_onHint);
    on<RestoreLife>(_onRestoreLife);
    on<AccentTutorPass>(_onTutorPass);
    on<RestartLevel>(_onRestart);
    on<AccentSpeakConfirmed>(_onSpeakConfirmed);
  }

  // ── FetchAccentQuests ────────────────────────────────────────────────────

  Future<void> _onFetch(
    FetchAccentQuests event,
    Emitter<AccentState> emit,
  ) async {
    _currentGameType = event.gameType.name;
    _currentLevel = event.level;

    emit(const AccentLoading());

    final result = await getQuest(
      GetAccentQuestParams(gameType: event.gameType, level: event.level),
    );

    result.fold((failure) => emit(AccentError(failure.message)), (quests) {
      if (quests.isEmpty) {
        emit(const AccentError('No quests available for this level.'));
        return;
      }
      emit(
        AccentLoaded(
          quests: quests.take(AccentGameConstants.questLimit).toList(),
          currentIndex: 0,
          livesRemaining: AccentGameConstants.maxLives,
          gameType: event.gameType,
          level: event.level,
        ),
      );
      onAnalyticsEvent?.call('accent_level_started', {
        'level': event.level,
        'game_type': event.gameType.name,
      });
    });
  }

  // ── PreloadBatch ─────────────────────────────────────────────────────────

  Future<void> _onPreload(PreloadBatch event, Emitter<AccentState> emit) async {
    // Fire-and-forget: preload the next level silently.
    // Cache misses are gracefully handled downstream as a network fetch.
    await preloadQuest(
      PreloadAccentQuestParams(
        gameType: event.gameType,
        level: event.currentLevel + 1,
      ),
    );
  }

  // ── RetryCurrentQuestion ─────────────────────────────────────────────────

  void _onRetry(RetryCurrentQuestion event, Emitter<AccentState> emit) {
    if (state is AccentLoaded) {
      final s = state as AccentLoaded;
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  // ── SubmitAnswer ─────────────────────────────────────────────────────────
  //
  // Single emit per answer — BLoC serialises events, so the
  // `lastAnswerCorrect != null` guard already prevents double-tap races.
  // The former premature "lockedState" emit that caused 2× rebuilds is gone.

  void _onSubmit(SubmitAnswer event, Emitter<AccentState> emit) {
    final s = state;
    if (s is! AccentLoaded ||
        s.livesRemaining <= 0 ||
        s.lastAnswerCorrect != null) {
      return;
    }

    if (!event.isCorrect) {
      final newLives = s.livesRemaining - 1;
      final newWrongCount = s.wrongCount + 1;
      final isFinal = newWrongCount >= 2;

      // Only append the Mastery Loop quest when the player still has lives.
      // If newLives == 0 the game is heading to GameOver; the extra entry is wasted.
      final shouldAppend = isFinal && newLives > 0;
      final updatedQuests = shouldAppend
          ? (List<AccentQuest>.from(s.quests)..add(s.currentQuest))
          : s.quests;

      soundService.playWrong();
      hapticService.error();

      emit(
        s.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          quests: updatedQuests,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    } else {
      soundService.playCorrect();
      hapticService.success();

      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    }
  }

  // ── NextQuestion ─────────────────────────────────────────────────────────

  Future<void> _onNext(NextQuestion event, Emitter<AccentState> emit) async {
    final s = state;
    if (s is! AccentLoaded) return;

    // Lives exhausted → game over.
    if (s.livesRemaining <= 0) {
      emit(
        AccentGameOver(
          quests: s.quests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
        ),
      );
      onAnalyticsEvent?.call('accent_game_over', {
        'level': s.level,
        'quest_index': s.currentIndex,
      });
      return;
    }

    final hasNext = s.currentIndex + 1 < s.quests.length;

    if (hasNext) {
      if (s.lastAnswerCorrect == true || s.isFinalFailure) {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      } else {
        // First wrong answer — stay on this quest.
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    } else if (s.lastAnswerCorrect == true) {
      // All quests complete → level won.
      soundService.playLevelComplete();

      emit(
        AccentGameComplete(
          xpEarned: AccentGameConstants.rewardXp,
          coinsEarned: AccentGameConstants.rewardCoins,
          questCount: s.quests.length,
          lastState: s,
        ),
      );

      onAnalyticsEvent?.call('accent_level_complete', {
        'level': _currentLevel,
        'quest_count': s.quests.length,
        'lives_remaining': s.livesRemaining,
      });

      if (_currentGameType != null && _currentLevel != null) {
        try {
          await Future.wait([
            updateUserRewards(
              UpdateUserRewardsParams(
                gameType: _currentGameType!,
                level: _currentLevel!,
                xpIncrease: AccentGameConstants.rewardXp,
                coinIncrease: AccentGameConstants.rewardCoins,
                starsEarned: s.livesRemaining,
              ),
            ),
            updateCategoryStats(
              UpdateCategoryStatsParams(
                categoryId: _currentGameType!,
                isCorrect: true,
              ),
            ),
            awardBadge(AccentGameConstants.accentMasterBadge),
          ]);
        } catch (e, stack) {
          // Reward sync failures must never degrade game-completion UX.
          // The error reporter (if wired) handles retry / logging.
          errorReporter?.call(e, stack);
        }
      }
    } else {
      // Wrong answer on the final quest — stay for retry.
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  // ── AccentHintUsed ───────────────────────────────────────────────────────

  Future<void> _onHint(AccentHintUsed event, Emitter<AccentState> emit) async {
    if (state is AccentLoaded) {
      final s = state as AccentLoaded;
      if (s.hintUsed) return;

      final result = await useHint(NoParams());
      if (result.isRight()) {
        emit(s.copyWith(hintUsed: true));
        hapticService.selection();
      }
    }
  }

  // ── RestoreLife ──────────────────────────────────────────────────────────

  void _onRestoreLife(RestoreLife event, Emitter<AccentState> emit) {
    if (state is AccentGameOver) {
      final s = state as AccentGameOver;
      emit(
        AccentLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          gameType: s.gameType,
          level: s.level,
        ),
      );
    }
  }

  // ── AccentTutorPass ──────────────────────────────────────────────────────

  void _onTutorPass(AccentTutorPass event, Emitter<AccentState> emit) {
    final s = state;

    if (s is AccentLoaded) {
      final newLives = (s.livesRemaining + 1).clamp(
        0,
        AccentGameConstants.maxLives,
      );
      final updatedQuests = s.quests.length > AccentGameConstants.questLimit
          ? (List<AccentQuest>.from(s.quests)..removeLast())
          : s.quests;

      soundService.playCorrect();
      hapticService.success();

      emit(
        s.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: true,
          quests: updatedQuests,
        ),
      );
    } else if (s is AccentGameOver) {
      soundService.playCorrect();
      hapticService.success();

      emit(
        AccentLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          lastAnswerCorrect: true,
          gameType: s.gameType,
          level: s.level,
        ),
      );
    }
  }

  // ── RestartLevel ─────────────────────────────────────────────────────────

  void _onRestart(RestartLevel event, Emitter<AccentState> emit) {
    clearCache(
      NoParams(),
    ); // Fire-and-forget; stale entries removed for next fetch.
    emit(const AccentInitial());
  }

  // ── AccentSpeakConfirmed ─────────────────────────────────────────────────

  Future<void> _onSpeakConfirmed(
    AccentSpeakConfirmed event,
    Emitter<AccentState> emit,
  ) async {
    try {
      await updateUserCoins(UpdateUserCoinsParams(
        amountChange: event.bonusCoins,
        title: 'coin_history.speaking_bonus',
        isEarned: true,
      ));
    } catch (e, stack) {
      errorReporter?.call(e, stack);
    }
  }
}
