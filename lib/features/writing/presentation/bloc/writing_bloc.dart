import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';

import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/core/usecases/usecase.dart';
import '../../domain/entities/writing_quest.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/writing/domain/usecases/get_writing_quest.dart';
import 'writing_event.dart';
import 'writing_state.dart';

// ---------------------------------------------------------------------------
// Writing Feature — BLoC
// Pure event-handler logic. No UI dependencies. No mutable instance fields.
// ---------------------------------------------------------------------------

class WritingBloc extends Bloc<WritingEvent, WritingState> {
  final GetWritingQuest getQuest;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;

  // ---------------------------------------------------------------------------
  // Domain Constants
  // These are the single source of truth for writing game rules.
  // _maxQuestsPerLevel should eventually come from remote config or the quest
  // entity so it can be A/B tested without a code deploy.
  // ---------------------------------------------------------------------------
  static const int _rewardXp = 10;
  static const int _rewardCoins = 10;
  static const String _writingBadgeId = 'writing_master';
  static const int _maxQuestsPerLevel = 3;
  static const int _wrongAnswerThreshold = 2;
  static const int _initialLives = 3;

  WritingBloc({
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.getQuest,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
  }) : super(const WritingInitial()) {
    on<FetchWritingQuests>(_onFetchQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<WritingHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RetryCurrentQuestion>(_onRetryCurrentQuestion);
    on<RestartLevel>((_, emit) => emit(const WritingInitial()));
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onFetchQuests(
    FetchWritingQuests event,
    Emitter<WritingState> emit,
  ) async {
    final GameSubtype subtype = event.gameType is GameSubtype
        ? event.gameType as GameSubtype
        : GameSubtype.values.firstWhere(
            (s) => s.name == event.gameType.toString(),
            orElse: () {
              // Surface routing bugs in debug without crashing production.
              assert(
                false,
                'WritingBloc: unknown GameSubtype "${event.gameType}"',
              );
              return GameSubtype.sentenceBuilder;
            },
          );

    emit(const WritingLoading());

    try {
      final result = await getQuest(
        GetWritingQuestParams(gameType: subtype, level: event.level),
      );

      result.fold(
        (failure) => emit(
          WritingError(failure.message, technicalError: failure.toString()),
        ),
        (quests) {
          if (quests.isEmpty) {
            emit(
              WritingError(
                "We couldn't find any quests for this level yet.",
                technicalError:
                    'Empty quest list for ${subtype.name}, Level ${event.level}',
              ),
            );
            return;
          }

          emit(
            WritingLoaded(
              quests: quests.take(_maxQuestsPerLevel).toList(),
              currentIndex: 0,
              livesRemaining: _initialLives,
              gameType: subtype, // FIX: now in state, not mutable field
              level: event.level, // FIX: now in state, not mutable field
            ),
          );
        },
      );
    } catch (e) {
      emit(WritingError('Failed to fetch quests: $e'));
    }
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<WritingState> emit,
  ) async {
    final s = state;
    if (s is! WritingLoaded || s.livesRemaining <= 0) return;

    if (!event.isCorrect) {
      final newLives = s.livesRemaining - 1;
      final newWrongCount = s.wrongCount + 1;
      final bool isFinal = newWrongCount >= _wrongAnswerThreshold;

      // Mastery Loop: re-queue the question so the learner must ultimately
      // answer it correctly before the level ends.
      final updatedQuests = isFinal
          ? (List<WritingQuest>.from(s.quests)..add(s.currentQuest))
          : s.quests;

      await soundService.playWrong();
      await hapticService.error();

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
      await soundService.playCorrect();
      await hapticService.success();

      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<WritingState> emit,
  ) async {
    final s = state;
    if (s is! WritingLoaded) return;

    // Lives-out check takes priority over all other transitions.
    if (s.livesRemaining <= 0) {
      emit(
        WritingGameOver(
          quests: s.quests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
        ),
      );
      return;
    }

    final bool hasMore = s.currentIndex + 1 < s.quests.length;
    final bool canAdvance = s.lastAnswerCorrect == true || s.isFinalFailure;

    if (hasMore) {
      if (canAdvance) {
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
        // First wrong answer — stay and retry.
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    } else if (s.lastAnswerCorrect == true) {
      await _completeLevel(s, emit);
    } else {
      // Wrong answer on the final question — stay and retry.
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  Future<void> _onHintUsed(
    WritingHintUsed event,
    Emitter<WritingState> emit,
  ) async {
    final s = state;
    if (s is! WritingLoaded || s.hintUsed) return;

    final result = await useHint(NoParams());
    if (result.isRight()) {
      emit(s.copyWith(hintUsed: true));
      hapticService.selection();
    }
  }

  void _onRestoreLife(RestoreLife event, Emitter<WritingState> emit) {
    final s = state;
    if (s is! WritingGameOver) return;

    emit(
      WritingLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        gameType: s.gameType,
        level: s.level,
      ),
    );
  }

  void _onRetryCurrentQuestion(
    RetryCurrentQuestion event,
    Emitter<WritingState> emit,
  ) {
    final s = state;
    if (s is! WritingLoaded) return;
    emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Emits [WritingGameComplete] immediately for instant UI feedback, then
  /// persists rewards in the background. A failing background save never
  /// disrupts the user's completion experience.
  Future<void> _completeLevel(
    WritingLoaded s,
    Emitter<WritingState> emit,
  ) async {
    soundService.playLevelComplete();

    // 1. Instant UI — emit before any awaited I/O.
    emit(
      WritingGameComplete(
        xpEarned: _rewardXp,
        coinsEarned: _rewardCoins,
        questCount: s.quests.length,
        gameType: s.gameType, // FIX: reads from state, not mutable field
        level: s.level, // FIX: reads from state, not mutable field
      ),
    );

    // 2. Background persistence — all 4 saves run in parallel.
    try {
      await Future.wait([
        updateUserRewards(
          UpdateUserRewardsParams(
            gameType: s.gameType.name,
            level: s.level,
            xpIncrease: _rewardXp,
            coinIncrease: _rewardCoins,
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
        awardBadge(_writingBadgeId),
      ]);
    } catch (e, st) {
      // FIX: guarded by kDebugMode — no sensitive error details in release logs.
      // Replace with FirebaseCrashlytics.instance.recordError(e, st) in production.
      if (kDebugMode) {
        debugPrint('[WritingBloc] Background reward save failed: $e\n$st');
      }
    }
  }
}
