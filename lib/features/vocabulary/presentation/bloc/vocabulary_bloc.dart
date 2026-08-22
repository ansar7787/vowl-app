import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
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

import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_event.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_state.dart';

export 'vocabulary_event.dart';
export 'vocabulary_state.dart';

// ─── Error-swallow helper ─────────────────────────────────────────────────────

/// Silently absorbs a [Failure] from a persistence use-case so that individual
/// reward failures never crash an in-progress game session.
Either<Failure, void> _swallow(Object _) => const Right(null);

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final GetVocabularyQuests getQuests;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  String? _currentGameType;
  int? _currentLevel;

  String? get currentGameType => _currentGameType;
  int? get currentLevel => _currentLevel;

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

    if (!await networkInfo.isConnected) {
      emit(
        const VocabularyError(
          'No internet connection. Please check your network and try again.',
          technicalError: 'NetworkInfo.isConnected returned false',
        ),
      );
      return;
    }

    try {
      // FIX: typed params object replaces positional (String, int) arguments,
      // matching the UseCase<Output, Params> contract used project-wide.
      final result = await getQuests(
        GetVocabularyQuestsParams(
          gameType: event.gameType.name,
          level: event.level,
        ),
      );

      result.fold(
        (failure) {
          emit(
            VocabularyError(
              'Failed to load quests. Please try again.',
              technicalError: failure.message,
            ),
          );
        },
        (quests) {
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
        debugPrint('[VocabularyBloc] _onFetchQuests: $e\n$st');
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

      // Mastery loop: append failed quest so the player must answer it
      // correctly before the level ends.
      final updatedQuests = isFinal ? [...s.quests, s.currentQuest] : s.quests;

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
        await _handleLevelComplete(s, emit);
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

  Future<void> _handleLevelComplete(
    VocabularyLoaded s,
    Emitter<VocabularyState> emit,
  ) async {
    await soundService.playLevelComplete();

    const xp = VocabularyRewardConstants.baseXp;
    const coins = VocabularyRewardConstants.baseCoins;

    emit(
      VocabularyGameComplete(
        xpEarned: xp,
        coinsEarned: coins,
        questCount: s.quests.length,
      ),
    );

    if (_currentGameType != null && _currentLevel != null) {
      final gameType = _currentGameType!;
      final level = _currentLevel!;

      // Parallel persistence — O(1) concurrent dispatch vs O(4) sequential.
      await Future.wait([
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
        // NOTE: AwardBadge must be idempotent at the use-case level —
        // it is called on every level completion.
        awardBadge(
          VocabularyRewardConstants.masteryBadgeId,
        ).catchError(_swallow),
      ]);
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
    final matched = GameSubtype.values.cast<GameSubtype?>().firstWhere(
      (e) => e?.name == _currentGameType,
      orElse: () => null,
    );
    if (matched != null) {
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
    (await useHint(NoParams())).fold((_) {}, (_) {
      emit(s.copyWith(hintUsed: true));
      hapticService.selection();
    });
  }

  // ── Restore life — O(1) ───────────────────────────────────────────────────

  void _onRestoreLife(RestoreLife _, Emitter<VocabularyState> emit) {
    if (state is! VocabularyGameOver) return;
    final s = state as VocabularyGameOver;
    emit(
      VocabularyLoaded(
        quests: s.quests,
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
