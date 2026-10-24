import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
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
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../domain/usecases/get_roleplay_quest.dart';
import '../../domain/entities/roleplay_quest.dart';
import '../../domain/usecases/preload_roleplay_quests.dart';
import 'roleplay_event.dart';
import 'roleplay_state.dart';
import 'package:vowl/features/profile/presentation/bloc/trophy_room_cubit.dart';

/// BLoC for the Roleplay feature.
///
/// Owns all game-state transitions and side-effect coordination
/// (sounds, haptics, rewards, analytics). No Flutter widget imports.
class RoleplayBloc extends Bloc<RoleplayEvent, RoleplayState> {
  /// Creates a [RoleplayBloc] instance with all required use cases and services.
  RoleplayBloc({
    required this.getQuest,
    required this.preloadQuests,
    required this.updateUserCoins,
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
    on<RoleplaySpeakConfirmed>(_onSpeakConfirmed);
  }

  /// Use case to fetch roleplay quests.
  final GetRoleplayQuest getQuest;

  /// Use case to preload upcoming roleplay quests.
  final PreloadRoleplayQuests preloadQuests;

  /// Use case to update user coins.
  final UpdateUserCoins updateUserCoins;

  /// Use case to update user rewards upon level completion.
  final UpdateUserRewards updateUserRewards;

  /// Use case to update category statistics.
  final UpdateCategoryStats updateCategoryStats;

  /// Use case to update the unlocked level.
  final UpdateUnlockedLevel updateUnlockedLevel;

  /// Use case to award badges.
  final AwardBadge awardBadge;

  /// Audio feedback service.
  final SoundService soundService;

  /// Tactile haptic feedback service.
  final HapticService hapticService;

  /// Use case to consume a hint.
  final UseHint useHint;

  /// Network connectivity info service.
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
          answerStatus: AnswerStatus.unanswered,
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
    if (s.livesRemaining <= 0 || s.answerStatus.isAnswered) return;

    final isCorrect = (event.choice.score ?? 100) >= 50;
    if (isCorrect) {
      emit(
        s.copyWith(
          answerStatus: AnswerStatus.correct,
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
          answerStatus: AnswerStatus.incorrect,
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
    if (s.livesRemaining <= 0 || s.answerStatus.isAnswered) return;

    if (event.isCorrect) {
      emit(
        s.copyWith(
          answerStatus: AnswerStatus.correct,
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
          answerStatus: AnswerStatus.incorrect,
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

    final canAdvance =
        s.answerStatus == AnswerStatus.correct || s.isFinalFailure;
    final isLastQuest = s.currentIndex + 1 >= s.quests.length;

    if (!isLastQuest) {
      if (canAdvance) {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            answerStatus: AnswerStatus.unanswered,
            hintUsed: false,
            currentNodeId: 'start',
            errorMessage: null,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      } else {
        emit(
          s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false),
        );
      }
      return;
    }

    if (s.answerStatus != AnswerStatus.correct) {
      emit(s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false));
      return;
    }

    // ── Level complete ─────────────────────────────────────────────────

    // 1. Instant UI feedback — emitted immediately to prevent double-taps on the
    // "Continue" button and eliminate UI delays.
    emit(
      RoleplayGameComplete(
        xpEarned: kRoleplayLevelCompleteXp,
        coinsEarned: kRoleplayLevelCompleteCoins,
        questCount: s.quests.length,
        lastState: s,
      ),
    );

    // 2. Background persistence — Single atomic transaction for rewards + progress.
    // Strictly awards standard level completion rewards (5 XP + 10 Coins).
    // Zero mid-game coins awarded, preventing Firestore rate-limit collisions.
    updateUserRewards(
          UpdateUserRewardsParams(
            gameType: s.gameType.name,
            level: s.level,
            xpIncrease: kRoleplayLevelCompleteXp,
            coinIncrease: kRoleplayLevelCompleteCoins,
            starsEarned: s.livesRemaining,
          ),
        )
        .then((result) {
          result.fold(
            (failure) {
              if (kDebugMode) {
                debugPrint('[RoleplayBloc] updateUserRewards failed: $failure');
              }
            },
            (_) {
              updateCategoryStats(
                UpdateCategoryStatsParams(
                  categoryId: s.gameType.name,
                  isCorrect: true,
                ),
              ).catchError((_) => const Right<Failure, void>(null));

              final milestoneBadge = TrophyRoomCubit.getMilestoneBadge(
                'roleplay',
                s.level,
              );
              if (milestoneBadge != null) {
                awardBadge(
                  milestoneBadge,
                ).catchError((_) => const Right<Failure, void>(null));
              }
            },
          );
        })
        .catchError((e) {
          if (kDebugMode) {
            debugPrint('[RoleplayBloc] updateUserRewards uncaught error: $e');
          }
        });
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
        if (kDebugMode) debugPrint('[RoleplayBloc] UseHint failed: $failure');
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

    // Production Defense: Prune duplicate copies of the revived question
    // that may have been appended after currentIndex, preventing duplicate replays.
    final sanitizedQuests = List<RoleplayQuest>.from(s.quests);
    if (s.currentIndex < sanitizedQuests.length) {
      final currentQuestId = sanitizedQuests[s.currentIndex].id;
      for (int i = sanitizedQuests.length - 1; i > s.currentIndex; i--) {
        if (sanitizedQuests[i].id == currentQuestId) {
          sanitizedQuests.removeAt(i);
        }
      }
    }

    emit(
      RoleplayLoaded(
        quests: sanitizedQuests,
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
      if (kDebugMode) {
        debugPrint(
          '[RoleplayBloc] PreloadNextBatch failed — will fetch on demand: $e',
        );
      }
    }
  }

  void _onSpeakConfirmed(
    RoleplaySpeakConfirmed event,
    Emitter<RoleplayState> emit,
  ) {
    // Per strict app architecture: verbal confirmations verify speech accuracy only
    // and never award mid-game coins. Rewards (5 XP + 10 Coins) are awarded strictly
    // upon level completion via updateUserRewards.
  }
}
