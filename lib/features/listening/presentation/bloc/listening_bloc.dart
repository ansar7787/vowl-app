import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listening_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_listening_quests.dart';
import 'listening_event.dart';
import 'listening_state.dart';
import 'listening_analytics.dart';
import '../../../../core/presentation/bloc/reward_retry_mixin.dart';

// ── Tuneable constants ────────────────────────────────────────────────────────

const int _kMaxLives = 3;
const int _kQuestionsPerLevel = 3;
const int _kXpReward = 5;
const int _kCoinReward = 10;
const int _kWrongBeforeFinal = 2;
const int _kMaxSaveRetries = 3;
const String _kListeningBadge = 'listening_master';

// ─────────────────────────────────────────────────────────────────────────────

/// BLoC managing auditory comprehension gameplay, audio playback states, lives, and rewards.
class ListeningBloc extends Bloc<ListeningEvent, ListeningState>
    with RewardRetryMixin {
  /// Use case for fetching listening quests.
  final GetListeningQuests getQuest;

  /// Use case persisting rewards (XP, gems) upon session completion.
  final UpdateUserRewards updateUserRewards;

  /// Use case updating category mastery statistics.
  final UpdateCategoryStats updateCategoryStats;

  /// Use case granting achievement badges.
  final AwardBadge awardBadge;

  /// Sound playback service for acoustic cues.
  final SoundService soundService;

  /// Haptic feedback service.
  final HapticService hapticService;

  /// Use case verifying and consuming hints.
  final UseHint useHint;

  /// Network connectivity service.
  final NetworkInfo networkInfo;

  /// Analytics are optional — defaults to no-op so tests require no mocking.
  final ListeningAnalytics analytics;

  /// Optional use case for coin rewards.
  final UpdateUserCoins? updateUserCoins;

  // Stored when FetchListeningQuests fires; used in background-save lambdas.
  String? _currentGameType;
  int? _currentLevel;

  /// Creates a [ListeningBloc] with required use cases and services.
  ListeningBloc({
    required this.getQuest,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
    this.analytics = const NoOpListeningAnalytics(),
    this.updateUserCoins,
  }) : super(const ListeningInitial()) {
    on<FetchListeningQuests>(_onFetch);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetry);
    on<ListeningHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<ListeningSpeakConfirmed>(_onSpeakConfirmed);
    on<RestartLevel>(_onRestartLevel);
    on<ListeningRewardSaveFailedEvent>((event, emit) {
      emit(
        ListeningRewardSaveFailed(
          xpEarned: event.xpEarned,
          coinsEarned: event.coinsEarned,
        ),
      );
    });
  }

  // ── FetchListeningQuests ──────────────────────────────────────────────────

  Future<void> _onFetch(
    FetchListeningQuests event,
    Emitter<ListeningState> emit,
  ) async {
    _currentGameType = event.gameType.name;
    _currentLevel = event.level;
    emit(const ListeningLoading());
    try {
      final result = await getQuest(
        GetListeningQuestsParams(gameType: event.gameType, level: event.level),
      );
      result.fold(
        (failure) => emit(ListeningError(failure.message)),
        (quests) => quests.isEmpty
            ? emit(const ListeningError('Check back later for new quests!'))
            : emit(
                ListeningLoaded(
                  quests: quests.take(_kQuestionsPerLevel).toList(),
                  currentIndex: 0,
                  livesRemaining: _kMaxLives,
                ),
              ),
      );
    } catch (e, stack) {
      if (kDebugMode) debugPrint('[ListeningBloc] fetch error: $e\n$stack');
      emit(
        ListeningError(
          'Failed to load quests. Please try again.',
          technicalError: e.toString(),
        ),
      );
    }
  }

  // ── SubmitAnswer ──────────────────────────────────────────────────────────

  void _onSubmitAnswer(SubmitAnswer event, Emitter<ListeningState> emit) {
    final s = state;
    if (s is! ListeningLoaded ||
        s.livesRemaining <= 0 ||
        s.answerStatus.isAnswered) {
      return;
    }

    analytics.onAnswerSubmitted(
      gameType: _currentGameType ?? '',
      level: _currentLevel ?? 0,
      questionIndex: s.currentIndex,
      isCorrect: event.isCorrect,
    );

    if (event.isCorrect) {
      soundService.playCorrect();
      hapticService.success();
      emit(
        s.copyWith(
          answerStatus: AnswerStatus.correct,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    } else {
      soundService.playWrong();
      hapticService.error();
      final newLives = s.livesRemaining - 1;
      final newWrongCount = s.wrongCount + 1;
      final isFinal = newWrongCount >= _kWrongBeforeFinal;

      // Production Guard: Only re-queue if player has lives remaining,
      // is not already at the last question, and hasn't already queued it.
      final isNotLastQuestion = s.currentIndex < s.quests.length - 1;
      final notAlreadyAppended = !s.quests
          .sublist(s.currentIndex + 1)
          .any((q) => q.id == s.currentQuest.id);
      final shouldAppend =
          isFinal && newLives > 0 && isNotLastQuestion && notAlreadyAppended;

      emit(
        s.copyWith(
          quests: shouldAppend
              ? (List<ListeningQuest>.from(s.quests)..add(s.currentQuest))
              : null,
          livesRemaining: newLives,
          answerStatus: AnswerStatus.incorrect,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    }
  }

  // ── NextQuestion ──────────────────────────────────────────────────────────

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<ListeningState> emit,
  ) async {
    final s = state;
    if (s is! ListeningLoaded) return;

    if (s.livesRemaining <= 0) {
      analytics.onGameOver(
        gameType: _currentGameType ?? '',
        level: _currentLevel ?? 0,
        questionsCompleted: s.currentIndex,
      );
      emit(ListeningGameOver(quests: s.quests, currentIndex: s.currentIndex));
      return;
    }

    final hasMore = s.currentIndex + 1 < s.quests.length;

    if (hasMore) {
      final canAdvance =
          s.answerStatus == AnswerStatus.correct || s.isFinalFailure;
      emit(
        canAdvance
            ? s.copyWith(
                currentIndex: s.currentIndex + 1,
                answerStatus: AnswerStatus.unanswered,
                hintUsed: false,
                wrongCount: 0,
                isFinalFailure: false,
              )
            : s.copyWith(
                answerStatus: AnswerStatus.unanswered,
                hintUsed: false,
              ),
      );
    } else if (s.answerStatus == AnswerStatus.correct) {
      _completeLevel(s, emit);
    } else {
      // Wrong on the final question — allow one more attempt.
      emit(s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false));
    }
  }

  // ── RetryCurrentQuestion ──────────────────────────────────────────────────

  void _onRetry(RetryCurrentQuestion event, Emitter<ListeningState> emit) {
    if (state is ListeningLoaded) {
      final s = state as ListeningLoaded;
      emit(s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false));
    }
  }

  // ── ListeningHintUsed ─────────────────────────────────────────────────────

  Future<void> _onHintUsed(
    ListeningHintUsed event,
    Emitter<ListeningState> emit,
  ) async {
    if (state is! ListeningLoaded) return;
    final s = state as ListeningLoaded;
    if (s.hintUsed) return;

    // Optimistic latch: prevent duplicate deductions from concurrent calls
    emit(s.copyWith(hintUsed: true));
    hapticService.selection();

    final result = await useHint(NoParams());
    result.fold(
      (failure) {
        if (state is ListeningLoaded) {
          emit((state as ListeningLoaded).copyWith(hintUsed: false));
        }
        hapticService.error();
        if (kDebugMode) {
          debugPrint('[ListeningBloc] UseHint failed: ${failure.message}');
        }
      },
      (_) {
        analytics.onHintUsed(
          gameType: _currentGameType ?? '',
          level: _currentLevel ?? 0,
          questionIndex: s.currentIndex,
        );
      },
    );
  }

  // ── RestoreLife ───────────────────────────────────────────────────────────

  void _onRestoreLife(RestoreLife event, Emitter<ListeningState> emit) {
    if (state is! ListeningGameOver) return;
    final s = state as ListeningGameOver;
    analytics.onLifeRestored(
      gameType: _currentGameType ?? '',
      level: _currentLevel ?? 0,
    );

    // Production Defense: Prune duplicate copies of the revived question
    // that may have been appended after currentIndex, preventing duplicate replays.
    final sanitizedQuests = List<ListeningQuest>.from(s.quests);
    if (s.currentIndex < sanitizedQuests.length) {
      final currentQuestId = sanitizedQuests[s.currentIndex].id;
      for (int i = sanitizedQuests.length - 1; i > s.currentIndex; i--) {
        if (sanitizedQuests[i].id == currentQuestId) {
          sanitizedQuests.removeAt(i);
        }
      }
    }

    emit(
      ListeningLoaded(
        quests: sanitizedQuests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      ),
    );
  }

  // ── RestartLevel ──────────────────────────────────────────────────────────

  void _onRestartLevel(RestartLevel event, Emitter<ListeningState> emit) =>
      emit(const ListeningInitial());

  // ── ListeningSpeakConfirmed ───────────────────────────────────────────────

  void _onSpeakConfirmed(
    ListeningSpeakConfirmed event,
    Emitter<ListeningState> emit,
  ) {
    // Per strict app architecture: verbal confirmations verify speech accuracy only
    // and never award mid-game coins. Rewards (5 XP + 10 Coins) are awarded strictly
    // upon level completion via updateUserRewards.
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Emits [ListeningGameComplete] immediately for snappy UI, then persists
  /// rewards in the background with up to [_kMaxSaveRetries] retries using
  /// exponential back-off so transient network errors don't silently lose XP.
  void _completeLevel(ListeningLoaded s, Emitter<ListeningState> emit) {
    // Capture non-null locals to avoid null assertions in async lambdas.
    final gameType = _currentGameType;
    final level = _currentLevel;

    analytics.onLevelComplete(
      gameType: gameType ?? '',
      level: level ?? 0,
      xpEarned: _kXpReward,
      coinsEarned: _kCoinReward,
    );

    // 1. UI feedback — emitted immediately to prevent double-taps on the
    // "Continue" button (which caused concurrent transaction aborts).
    emit(
      const ListeningGameComplete(
        xpEarned: _kXpReward,
        coinsEarned: _kCoinReward,
        questCount: _kQuestionsPerLevel,
      ),
    );

    // 2. Primary & Secondary persistence — Fire-and-forget.
    if (gameType != null && level != null) {
      _savePrimaryWithRetry(gameType, level, s.livesRemaining).then((_) {
        updateCategoryStats(
          UpdateCategoryStatsParams(categoryId: gameType, isCorrect: true),
        ).catchError((e, stack) {
          if (kDebugMode) {
            debugPrint('[ListeningBloc] Stats save failed: $e\n$stack');
          }
          return const Right<Failure, void>(null);
        });
        awardBadge(_kListeningBadge).catchError((e, stack) {
          if (kDebugMode) {
            debugPrint('[ListeningBloc] Badge failed: $e\n$stack');
          }
          return const Right<Failure, void>(null);
        });
      });
    }
  }

  /// Persists the primary reward (updateUserRewards) with retry.
  /// updateUserRewards already atomically updates completedLevels and
  /// unlockedLevels inside _computeRewardUpdates, so a separate
  /// updateUnlockedLevel call is intentionally omitted to avoid
  /// Firestore transaction contention on the same document.
  Future<void> _savePrimaryWithRetry(
    String gameType,
    int level,
    int starsEarned,
  ) async {
    await saveWithRetry(
      tag: 'ListeningBloc',
      action: () => updateUserRewards(
        UpdateUserRewardsParams(
          gameType: gameType,
          level: level,
          xpIncrease: _kXpReward,
          coinIncrease: _kCoinReward,
          starsEarned: starsEarned,
        ),
      ),
      onFinalFailure: () {
        if (kDebugMode) {
          debugPrint(
            '[ListeningBloc] All $_kMaxSaveRetries save attempts failed.',
          );
        }
        // Notify the UI so it can show a non-blocking snackbar.
        add(
          const ListeningRewardSaveFailedEvent(
            xpEarned: _kXpReward,
            coinsEarned: _kCoinReward,
          ),
        );
      },
    );
  }
}
