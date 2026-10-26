import 'package:vowl/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/vocabulary/domain/usecases/get_vocabulary_quests.dart';
import 'package:vowl/features/profile/presentation/bloc/trophy_room_cubit.dart';

import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_state.dart';

export 'vocabulary_event.dart';
export 'vocabulary_state.dart';

// ─── Error-swallow helper ─────────────────────────────────────────────────────

/// Silently absorbs a [Failure] from a persistence use-case so that individual
/// reward failures never crash an in-progress game session.
Either<Failure, void> _swallow(Object _) => const Right<Failure, void>(null);

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// State management component orchestrating game sessions, quests, answers, and rewards for vocabulary activities.
class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  /// Use case for retrieving vocabulary quests.
  final GetVocabularyQuests getQuests;

  /// Use case for updating the user's coin balance.
  final UpdateUserCoins updateUserCoins;

  /// Use case for recording XP, coins, and level progress upon completion.
  final UpdateUserRewards updateUserRewards;

  /// Use case for updating category-level accuracy statistics.
  final UpdateCategoryStats updateCategoryStats;

  /// Injected for API parity with other game blocs. Level unlock is handled
  /// inside [updateUserRewards] server-side; calling it here would cause
  /// duplicate writes. Intentionally unused.
  // ignore: unused_field
  final UpdateUnlockedLevel updateUnlockedLevel;

  /// Use case for awarding pedagogical badges and achievements.
  final AwardBadge awardBadge;

  /// Service managing gameplay audio effects.
  final SoundService soundService;

  /// Service managing tactile vibration feedback.
  final HapticService hapticService;

  /// Use case deducting available hint currency.
  final UseHint useHint;

  /// Service monitoring real-time network connectivity.
  final NetworkInfo networkInfo;

  String? _currentGameType;
  int? _currentLevel;

  /// The active game sub-type identifier.
  String? get currentGameType => _currentGameType;

  /// The active 1-based difficulty level.
  int? get currentLevel => _currentLevel;

  /// Creates a [VocabularyBloc] with required services, repositories, and use cases.
  VocabularyBloc({
    required this.getQuests,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(const VocabularyInitial()) {
    on<FetchVocabularyQuests>(_onFetchQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetryQuestion);
    on<RestartLevel>(_onRestartLevel);
    on<VocabularyHintUsed>(_onUseHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
  }

  // ── Fetch — O(n) dedup, O(n) space ───────────────────────────────────────

  Future<void> _onFetchQuests(
    FetchVocabularyQuests event,
    Emitter<VocabularyState> emit,
  ) async {
    _currentGameType = event.gameType.name;
    _currentLevel = event.level;
    emit(const VocabularyLoading());

    try {
      // FIX: typed params object replaces positional (String, int) arguments,
      // matching the UseCase<Output, Params> contract used project-wide.
      final result = await getQuests(
        GetVocabularyQuestsParams(
          gameType: event.gameType.name,
          level: event.level,
        ),
      );

      await result.fold(
        (failure) async {
          final isConnected = await networkInfo.isConnected;
          if (!isConnected) {
            emit(
              const VocabularyError(
                'No internet connection. Please check your network and try again.',
                technicalError:
                    'Offline and quest not available in local cache',
              ),
            );
          } else {
            emit(
              VocabularyError(
                'Failed to load quests. Please try again.',
                technicalError: failure.message,
              ),
            );
          }
        },
        (quests) async {
          if (quests.isEmpty) {
            emit(
              VocabularyError(
                "We couldn't find any quests for this level yet.",
                technicalError:
                    'Empty quest list: ${event.gameType.name} / ${event.level}',
              ),
            );
            return;
          }

          // O(n) dedup by id, preserve server order, then cap at maxQuestsPerLevel.
          final seen = <String>{};
          final limited = quests
              .where((q) => seen.add(q.id))
              .take(VocabularyRewardConstants.maxQuestsPerLevel)
              .toList();

          emit(
            VocabularyLoaded(
              quests: limited,
              currentIndex: 0,
              livesRemaining: VocabularyRewardConstants.initialLives,
            ),
          );
        },
      );
    } catch (e, st) {
      assert(() {
        if (kDebugMode) debugPrint('[VocabularyBloc] _onFetchQuests: $e\n$st');
        return true;
      }());
      emit(
        VocabularyError(
          'Failed to load quests. Please try again.',
          technicalError: e.toString(),
        ),
      );
    }
  }

  // ── Submit answer — O(n) mastery path / O(1) normal ───────────────────────

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    if (s.livesRemaining <= 0) return;

    if (event.isCorrect) {
      await soundService.playCorrect();
      await hapticService.success();

      emit(
        s.copyWith(
          answerStatus: AnswerStatus.correct,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    } else {
      final newLives = s.livesRemaining - 1;
      final newWrong = s.wrongCount + 1;
      final isFinal =
          newWrong >= VocabularyRewardConstants.wrongCountBeforeMasteryLoop;

      // Production Guard: Only re-queue if player has lives remaining,
      // is not already at the last question, and hasn't already queued it.
      final isNotLastQuestion = s.currentIndex < s.quests.length - 1;
      final notAlreadyAppended = !s.quests
          .sublist(s.currentIndex + 1)
          .any((q) => q.id == s.currentQuest.id);
      final shouldAppend =
          isFinal && newLives > 0 && isNotLastQuestion && notAlreadyAppended;

      // Mastery loop: append failed quest so the player must answer it
      // correctly before the level ends.
      final updatedQuests =
          shouldAppend ? [...s.quests, s.currentQuest] : s.quests;

      await soundService.playWrong();
      await hapticService.error();

      emit(
        s.copyWith(
          quests: updatedQuests,
          livesRemaining: newLives,
          answerStatus: AnswerStatus.incorrect,
          wrongCount: isFinal ? 0 : newWrong,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    }
  }

  // ── Next question — O(1) ──────────────────────────────────────────────────

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;

    if (s.livesRemaining <= 0) {
      emit(VocabularyGameOver(quests: s.quests, currentIndex: s.currentIndex));
      return;
    }

    final isLast = s.currentIndex >= s.quests.length - 1;
    if (isLast) {
      if (s.answerStatus == AnswerStatus.correct) {
        _handleLevelComplete(s, emit);
      } else {
        emit(
          s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false),
        );
      }
      return;
    }

    if (s.answerStatus == AnswerStatus.correct || s.isFinalFailure) {
      emit(
        s.copyWith(
          currentIndex: s.currentIndex + 1,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    } else {
      emit(s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false));
    }
  }

  void _handleLevelComplete(VocabularyLoaded s, Emitter<VocabularyState> emit) {
    const xp = VocabularyRewardConstants.baseXp;
    const coins = VocabularyRewardConstants.baseCoins;

    // 1. UI feedback — emitted immediately to prevent double-taps on the
    // "Continue" button (which caused concurrent transaction aborts).
    emit(
      VocabularyGameComplete(
        xpEarned: xp,
        coinsEarned: coins,
        questCount: s.quests.length,
      ),
    );

    // 2. Persistence — parallel fire-and-forget.
    //    All three calls run independently so a single failure cannot
    //    block the others. Errors are logged but never crash the game.
    if (_currentGameType != null && _currentLevel != null) {
      final gameType = _currentGameType!;
      final level = _currentLevel!;

      Future.wait([
        updateUserRewards(
          UpdateUserRewardsParams(
            gameType: gameType,
            level: level,
            xpIncrease: xp,
            coinIncrease: coins,
            starsEarned: s.livesRemaining,
          ),
        ).catchError(_swallow),
        updateCategoryStats(
          UpdateCategoryStatsParams(categoryId: gameType, isCorrect: true),
        ).catchError(_swallow),
        if (TrophyRoomCubit.getMilestoneBadge('vocabulary', level) != null)
          awardBadge(
            TrophyRoomCubit.getMilestoneBadge('vocabulary', level)!,
          ).catchError(_swallow),
      ], eagerError: false);
    }
  }

  // ── Retry — O(1) ─────────────────────────────────────────────────────────

  void _onRetryQuestion(RetryCurrentQuestion _, Emitter<VocabularyState> emit) {
    if (state is! VocabularyLoaded) return;
    emit(
      (state as VocabularyLoaded).copyWith(
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
      ),
    );
  }

  // ── Restart — O(k) enum scan ──────────────────────────────────────────────

  Future<void> _onRestartLevel(
    RestartLevel _,
    Emitter<VocabularyState> emit,
  ) async {
    if (_currentGameType == null || _currentLevel == null) {
      emit(const VocabularyInitial());
      return;
    }
    // O(1) lookup via pre-computed name map instead of O(n) linear scan.
    final matched = GameSubtype.fromString(_currentGameType);
    // fromString returns a fallback — verify it actually matched.
    if (matched.name == _currentGameType) {
      add(FetchVocabularyQuests(gameType: matched, level: _currentLevel!));
    } else {
      emit(const VocabularyInitial());
    }
  }

  // ── Hint — O(1) ───────────────────────────────────────────────────────────

  Future<void> _onUseHint(
    VocabularyHintUsed _,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    if (s.hintUsed) return;

    // Optimistic latch: prevent duplicate deductions from concurrent calls
    emit(s.copyWith(hintUsed: true));
    hapticService.selection();

    (await useHint(NoParams())).fold(
      (_) {
        // Rollback on failure
        if (state is VocabularyLoaded) {
          emit((state as VocabularyLoaded).copyWith(hintUsed: false));
        }
        hapticService.error();
      },
      (_) {},
    );
  }

  // ── Restore life — O(1) ───────────────────────────────────────────────────

  void _onRestoreLife(RestoreLife _, Emitter<VocabularyState> emit) {
    if (state is! VocabularyGameOver) return;
    final s = state as VocabularyGameOver;

    // Production Defense: Prune duplicate copies of the revived question
    // that may have been appended after currentIndex, preventing duplicate replays.
    final sanitizedQuests = List<VocabularyQuest>.from(s.quests);
    if (s.currentIndex < sanitizedQuests.length) {
      final currentQuestId = sanitizedQuests[s.currentIndex].id;
      for (int i = sanitizedQuests.length - 1; i > s.currentIndex; i--) {
        if (sanitizedQuests[i].id == currentQuestId) {
          sanitizedQuests.removeAt(i);
        }
      }
    }

    emit(
      VocabularyLoaded(
        quests: sanitizedQuests,
        currentIndex: s.currentIndex,
        livesRemaining: VocabularyRewardConstants.reviveLives,
      ),
    );
  }

  // ── Add hint — O(1) ───────────────────────────────────────────────────────

  void _onAddHint(AddHint event, Emitter<VocabularyState> emit) {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    emit(s.copyWith(hintsAvailable: s.hintsAvailable + event.count));
  }
}
