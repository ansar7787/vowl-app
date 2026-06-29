import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/roleplay/presentation/constants/roleplay_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../domain/usecases/get_roleplay_quest.dart';
import '../../domain/usecases/preload_roleplay_quests.dart';
import 'roleplay_event.dart';
import 'roleplay_state.dart';

/// BLoC for the Roleplay feature.
///
/// Owns all game-state transitions and side-effect coordination
/// (sounds, haptics, rewards, analytics). No Flutter widget imports.
class RoleplayBloc extends Bloc<RoleplayEvent, RoleplayState> {
  RoleplayBloc({
    required this.getQuest,
    required this.preloadQuests,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(const RoleplayInitial()) {
    on<FetchRoleplayQuests>(_onFetch);
    on<RetryCurrentQuestion>(_onRetry);
    on<SelectDialogueChoice>(_onSelectDialogue);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RoleplayHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RestartLevel>(_onRestart);
    on<PreloadNextBatch>(_onPreload);
  }

  final GetRoleplayQuest getQuest;
  final PreloadRoleplayQuests preloadQuests;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    FetchRoleplayQuests event,
    Emitter<RoleplayState> emit,
  ) async {
    emit(const RoleplayLoading());

    final result = await getQuest(
      GetRoleplayQuestParams(gameType: event.gameType, level: event.level),
    );
    result.fold(
      (failure) => emit(
        RoleplayError(
          'Failed to load quests. Please try again.',
          technicalError: failure.toString(),
        ),
      ),
      (quests) {
        if (quests.isEmpty) {
          emit(const RoleplayError('No quests available for this level.'));
          return;
        }
        if (event.level % kRoleplayPreloadTriggerModulo == 0) {
          add(
            PreloadNextBatch(
              gameType: event.gameType,
              currentLevel: event.level,
            ),
          );
        }
        emit(
          RoleplayLoaded(
            quests: quests,
            currentIndex: 0,
            livesRemaining: quests.first.livesAllowed,
            gameType: event.gameType,
            level: event.level,
            currentNodeId: 'start',
          ),
        );
      },
    );
  }

  // ── ─────────────────────────────────────────────────────────────────────

  void _onRetry(RetryCurrentQuestion event, Emitter<RoleplayState> emit) {
    if (state is RoleplayLoaded) {
      emit(
        (state as RoleplayLoaded).copyWith(
          lastAnswerCorrect: null,
          hintUsed: false,
        ),
      );
    }
  }

  // ── ─────────────────────────────────────────────────────────────────────

  void _onSelectDialogue(
    SelectDialogueChoice event,
    Emitter<RoleplayState> emit,
  ) {
    if (state is! RoleplayLoaded) return;
    final s = state as RoleplayLoaded;
    if (s.livesRemaining <= 0 || s.lastAnswerCorrect != null) return;

    final isCorrect = (event.choice.score ?? 100) >= 50;
    if (isCorrect) {
      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          currentNodeId: event.choice.next,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
      soundService.playCorrect();
      hapticService.success();
    } else {
      final r = processWrongAnswer(s);
      emit(
        s.copyWith(
          livesRemaining: r.newLives,
          lastAnswerCorrect: false,
          quests: r.updatedQuests,
          currentNodeId: event.choice.next,
          wrongCount: r.newWrongCount,
          isFinalFailure: r.isFinalFailure,
        ),
      );
      soundService.playWrong();
      hapticService.error();
    }
  }

  // ── ─────────────────────────────────────────────────────────────────────

  /// Handles the options-list answer path.
  ///
  /// The screen is responsible for the tap animation and delay; this handler
  /// only updates state and fires audio/haptic feedback.
  void _onSubmitAnswer(SubmitAnswer event, Emitter<RoleplayState> emit) {
    if (state is! RoleplayLoaded) return;
    final s = state as RoleplayLoaded;
    if (s.livesRemaining <= 0 || s.lastAnswerCorrect != null) return;

    if (event.isCorrect) {
      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
      soundService.playCorrect();
      hapticService.success();
    } else {
      final r = processWrongAnswer(s);
      emit(
        s.copyWith(
          livesRemaining: r.newLives,
          lastAnswerCorrect: false,
          quests: r.updatedQuests,
          wrongCount: r.newWrongCount,
          isFinalFailure: r.isFinalFailure,
        ),
      );
      soundService.playWrong();
      hapticService.error();
    }
  }

  // ── ─────────────────────────────────────────────────────────────────────

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<RoleplayState> emit,
  ) async {
    if (state is! RoleplayLoaded) return;
    final s = state as RoleplayLoaded;

    if (s.livesRemaining <= 0) {
      emit(
        RoleplayGameOver(
          quests: s.quests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
        ),
      );
      return;
    }

    final canAdvance = s.lastAnswerCorrect == true || s.isFinalFailure;
    final isLastQuest = s.currentIndex + 1 >= s.quests.length;

    if (!isLastQuest) {
      if (canAdvance) {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
            currentNodeId: 'start',
            errorMessage: null,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      } else {
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
      return;
    }

    if (s.lastAnswerCorrect != true) {
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      return;
    }

    // ── Level complete — emit terminal state before async calls to
    // prevent double-tap advancing past the completion screen.
    emit(
      RoleplayGameComplete(
        xpEarned: kRoleplayLevelCompleteXp,
        coinsEarned: kRoleplayLevelCompleteCoins,
        questCount: s.quests.length,
        lastState: s,
      ),
    );

    soundService.playLevelComplete();

    // Sequential awaits match the original pattern and avoid Future.wait<T>
    // inference failures when use-cases have mixed or void return types.
    await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: s.gameType.name,
        level: s.level,
        xpIncrease: kRoleplayLevelCompleteXp,
        coinIncrease: kRoleplayLevelCompleteCoins, starsEarned: state is RoleplayLoaded ? (state as RoleplayLoaded).livesRemaining : 1,
      ),
    );
    await updateCategoryStats(
      UpdateCategoryStatsParams(categoryId: s.gameType.name, isCorrect: true),
    );
    await awardBadge(kRoleplayBadgeId);
  }

  // ── ─────────────────────────────────────────────────────────────────────

  Future<void> _onHintUsed(
    RoleplayHintUsed event,
    Emitter<RoleplayState> emit,
  ) async {
    if (state is! RoleplayLoaded) return;
    final s = state as RoleplayLoaded;
    if (s.hintUsed) return;

    emit(s.copyWith(hintUsed: true));
    hapticService.selection();

    final result = await useHint(NoParams());
    result.fold(
      (failure) {
        // Revert the latch so the player keeps their hint token.
        if (state is RoleplayLoaded) {
          emit((state as RoleplayLoaded).copyWith(hintUsed: false));
        }
        debugPrint('[RoleplayBloc] UseHint failed: $failure');
      },
      (_) {
        /* debit confirmed */
      },
    );
  }

  // ── ─────────────────────────────────────────────────────────────────────

  void _onRestoreLife(RestoreLife event, Emitter<RoleplayState> emit) {
    if (state is! RoleplayGameOver) return;
    final s = state as RoleplayGameOver;
    emit(
      RoleplayLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        gameType: s.gameType,
        level: s.level,
        currentNodeId: 'start',
      ),
    );
  }

  // ── ─────────────────────────────────────────────────────────────────────

  void _onRestart(RestartLevel event, Emitter<RoleplayState> emit) =>
      emit(const RoleplayInitial());

  // ── ─────────────────────────────────────────────────────────────────────

  Future<void> _onPreload(
    PreloadNextBatch event,
    Emitter<RoleplayState> emit,
  ) async {
    // Preloading is best-effort fire-and-forget: the original code discarded
    // the result entirely. We wrap in try/catch so a failed preload logs
    // without crashing, but we never modify state — the next batch will fetch
    // on demand if this call fails.
    try {
      await preloadQuests(
        gameType: event.gameType,
        currentLevel: event.currentLevel,
      );
    } catch (e) {
      debugPrint(
        '[RoleplayBloc] PreloadNextBatch failed — will fetch on demand: $e',
      );
    }
  }
}

