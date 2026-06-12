import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/haptic_service.dart';

import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'speaking_event.dart';
import 'speaking_state.dart';

export 'speaking_event.dart';
export 'speaking_state.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int _kMaxLives = 3;
const int _kMaxQuestsPerLevel = 3;

/// Hard upper-bound on the in-session quest queue. Prevents unbounded growth
/// when a student fails the mastery-loop quest repeatedly.
const int _kMaxQueueLength = _kMaxQuestsPerLevel * 2;

const int _kWrongCountThreshold = 2;
const int _kDefaultXp = 10;
const int _kDefaultCoins = 10;

// : Move badge IDs to a shared BadgeConstants class.
const String _kSpeakingMasterBadge = 'speaking_master';

// =============================================================================
// SpeakingBloc
// =============================================================================

class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final GetSpeakingQuest getQuest;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final AppLogger _logger;

  SpeakingBloc({
    required this.getQuest,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    AppLogger logger = const DebugAppLogger(),
  }) : _logger = logger,
       super(const SpeakingInitial()) {
    on<FetchSpeakingQuests>(_onFetch);
    on<RestartLevel>(_onRestart);
    on<RetryCurrentQuestion>(_onRetry);
    on<SpeakingHintUsed>(_onHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
    on<SpeakingTutorPass>(_onTutorPass);
    on<SubmitAnswer>(_onSubmit);
    on<NextQuestion>(_onNext);
  }

  // ---------------------------------------------------------------------------
  // FetchSpeakingQuests
  // ---------------------------------------------------------------------------

  Future<void> _onFetch(
    FetchSpeakingQuests event,
    Emitter<SpeakingState> emit,
  ) async {
    if (state is SpeakingLoading) return;
    emit(const SpeakingLoading());

    final result = await getQuest(
      GetSpeakingQuestParams(gameType: event.gameType, level: event.level),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        SpeakingError(
          failure.message,
          technicalError: 'Failure: ${failure.runtimeType}',
        ),
      ),
      (quests) {
        if (quests.isEmpty) {
          emit(
            SpeakingError(
              'Check back later for new quests!',
              technicalError:
                  'Empty list: ${event.gameType.name}, level ${event.level}',
            ),
          );
          return;
        }
        emit(
          SpeakingLoaded(
            quests: quests.take(_kMaxQuestsPerLevel).toList(),
            currentIndex: 0,
            livesRemaining: _kMaxLives,
            gameType: event.gameType,
            level: event.level,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // RestartLevel
  // ---------------------------------------------------------------------------

  void _onRestart(RestartLevel event, Emitter<SpeakingState> emit) =>
      emit(const SpeakingInitial());

  // ---------------------------------------------------------------------------
  // RetryCurrentQuestion
  // ---------------------------------------------------------------------------

  void _onRetry(RetryCurrentQuestion event, Emitter<SpeakingState> emit) {
    final s = state;
    if (s is SpeakingLoaded) {
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  // ---------------------------------------------------------------------------
  // SubmitAnswer
  // ---------------------------------------------------------------------------

  void _onSubmit(SubmitAnswer event, Emitter<SpeakingState> emit) {
    final s = state;
    if (s is! SpeakingLoaded || s.livesRemaining <= 0) return;
    if (s.lastAnswerCorrect != null) return; // feedback already visible

    if (!event.isCorrect) {
      final newLives = s.livesRemaining - 1;
      final newWrong = s.wrongCount + 1;
      final isFinal = newWrong >= _kWrongCountThreshold;

      final updated = List<SpeakingQuest>.from(s.quests);
      // Only re-queue for mastery loop if:
      //   • student has failed twice (isFinal)
      //   • lives will remain (game not over)
      //   • hard cap not yet reached (prevents unbounded growth)
      if (isFinal && newLives > 0 && updated.length < _kMaxQueueLength) {
        updated.add(s.currentQuest);
      }

      unawaited(soundService.playWrong());
      unawaited(hapticService.error());

      emit(
        s.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          quests: updated,
          wrongCount: isFinal ? 0 : newWrong,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    } else {
      unawaited(soundService.playCorrect());
      unawaited(hapticService.success());
      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // NextQuestion
  // ---------------------------------------------------------------------------

  Future<void> _onNext(NextQuestion event, Emitter<SpeakingState> emit) async {
    final s = state;
    if (s is! SpeakingLoaded) return;
    if (s.lastAnswerCorrect == null) return; // no answer submitted yet

    if (s.livesRemaining <= 0) {
      emit(
        SpeakingGameOver(
          quests: s.quests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
        ),
      );
      return;
    }

    final wasCorrect = s.lastAnswerCorrect == true;
    final isLastQuestion = s.currentIndex + 1 >= s.quests.length;

    if (isLastQuestion) {
      if (wasCorrect) {
        await _handleLevelComplete(s, emit);
      } else {
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
      return;
    }

    if (wasCorrect || s.isFinalFailure) {
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
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  /// Emits [SpeakingGameComplete] immediately then persists rewards in the
  /// background. Failures are silent because the UI has already advanced.
  Future<void> _handleLevelComplete(
    SpeakingLoaded s,
    Emitter<SpeakingState> emit,
  ) async {
    unawaited(soundService.playLevelComplete());

    // : Derive xp/coins from quest metadata (q.xpReward ?? _kDefaultXp)
    // once SpeakingQuest exposes reward fields.
    const xp = _kDefaultXp;
    const coins = _kDefaultCoins;

    emit(
      SpeakingGameComplete(
        xpEarned: xp,
        coinsEarned: coins,
        questCount: s.quests.length,
      ),
    );

    try {
      await Future.wait([
        updateUserRewards(
          UpdateUserRewardsParams(
            gameType: s.gameType.name,
            level: s.level,
            xpIncrease: xp,
            coinIncrease: coins,
          ),
        ),
        updateCategoryStats(
          UpdateCategoryStatsParams(
            categoryId: s.gameType.name,
            isCorrect: true,
          ),
        ),
        updateUnlockedLevel(
          UpdateUnlockedLevelParams(
            categoryId: s.gameType.name,
            newLevel: s.level + 1,
          ),
        ),
        awardBadge(_kSpeakingMasterBadge),
      ]);
    } catch (e, st) {
      _logger.error(
        'Background save failed after level complete',
        error: e,
        stackTrace: st,
        tag: 'SpeakingBloc',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UseHint
  // ---------------------------------------------------------------------------

  Future<void> _onHint(
    SpeakingHintUsed event,
    Emitter<SpeakingState> emit,
  ) async {
    final s = state;
    if (s is! SpeakingLoaded || s.hintUsed) return;

    final result = await useHint(NoParams());
    if (isClosed) return;

    final latest = state;
    if (latest is SpeakingLoaded && result.isRight()) {
      emit(latest.copyWith(hintUsed: true));
      unawaited(hapticService.selection());
    }
  }

  // ---------------------------------------------------------------------------
  // RestoreLife
  // ---------------------------------------------------------------------------

  void _onRestoreLife(RestoreLife event, Emitter<SpeakingState> emit) {
    final s = state;
    if (s is! SpeakingGameOver) return;
    emit(
      SpeakingLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        gameType: s.gameType,
        level: s.level,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AddHint (intentional no-op — see event doc)
  // ---------------------------------------------------------------------------
  void _onAddHint(AddHint event, Emitter<SpeakingState> emit) {}

  // ---------------------------------------------------------------------------
  // TutorPass
  // ---------------------------------------------------------------------------

  void _onTutorPass(SpeakingTutorPass event, Emitter<SpeakingState> emit) {
    final s = state;

    if (s is SpeakingLoaded) {
      final newLives = (s.livesRemaining + 1).clamp(0, _kMaxLives);
      final updated = List<SpeakingQuest>.from(s.quests);
      if (updated.length > _kMaxQuestsPerLevel) updated.removeLast();

      unawaited(soundService.playCorrect());
      unawaited(hapticService.success());

      emit(
        s.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: true,
          quests: updated,
        ),
      );
    } else if (s is SpeakingGameOver) {
      unawaited(soundService.playCorrect());
      unawaited(hapticService.success());

      emit(
        SpeakingLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          gameType: s.gameType,
          level: s.level,
          lastAnswerCorrect: true,
        ),
      );
    }
  }
}
