import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listening_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_listening_quests.dart';
import 'listening_event.dart';
import 'listening_state.dart';
import 'listening_analytics.dart';

// ── Tuneable constants ────────────────────────────────────────────────────────

const int _kMaxLives = 3;
const int _kQuestionsPerLevel = 3;
const int _kXpReward = 10;
const int _kCoinReward = 10;
const int _kWrongBeforeFinal = 2;
const int _kMaxSaveRetries = 3;
const String _kListeningBadge = 'listening_master';

// ─────────────────────────────────────────────────────────────────────────────

class ListeningBloc extends Bloc<ListeningEvent, ListeningState> {
  final GetListeningQuests getQuest;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  /// Analytics are optional — defaults to no-op so tests require no mocking.
  final ListeningAnalytics analytics;

  // Stored when FetchListeningQuests fires; used in background-save lambdas.
  String? _currentGameType;
  int? _currentLevel;

  ListeningBloc({
    required this.getQuest,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
    this.analytics = const NoOpListeningAnalytics(),
    // Backward-compat shim: accepted but intentionally unused.
    // Remove once DI registrations are cleaned up (coinIncrease is handled
    // ignore: avoid_unused_constructor_parameters
    UpdateUserCoins? updateUserCoins,
  }) : super(const ListeningInitial()) {
    on<FetchListeningQuests>(_onFetch);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetry);
    on<ListeningHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RestartLevel>(_onRestartLevel);
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
      debugPrint('[ListeningBloc] fetch error: $e\n$stack');
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
        s.lastAnswerCorrect != null) {
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
          lastAnswerCorrect: true,
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
      emit(
        s.copyWith(
          quests: isFinal
              ? (List<ListeningQuest>.from(s.quests)..add(s.currentQuest))
              : null,
          livesRemaining: newLives,
          lastAnswerCorrect: false,
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
      final canAdvance = s.lastAnswerCorrect == true || s.isFinalFailure;
      emit(
        canAdvance
            ? s.copyWith(
                currentIndex: s.currentIndex + 1,
                lastAnswerCorrect: null,
                hintUsed: false,
                wrongCount: 0,
                isFinalFailure: false,
              )
            : s.copyWith(lastAnswerCorrect: null, hintUsed: false),
      );
    } else if (s.lastAnswerCorrect == true) {
      await _completeLevel(s, emit);
    } else {
      // Wrong on the final question — allow one more attempt.
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  // ── RetryCurrentQuestion ──────────────────────────────────────────────────

  void _onRetry(RetryCurrentQuestion event, Emitter<ListeningState> emit) {
    if (state is ListeningLoaded) {
      final s = state as ListeningLoaded;
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
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

    final result = await useHint(NoParams());
    result.fold(
      (failure) =>
          debugPrint('[ListeningBloc] UseHint failed: ${failure.message}'),
      (_) {
        analytics.onHintUsed(
          gameType: _currentGameType ?? '',
          level: _currentLevel ?? 0,
          questionIndex: s.currentIndex,
        );
        emit(s.copyWith(hintUsed: true));
        hapticService.selection();
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
    emit(
      ListeningLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        lastAnswerCorrect: null,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      ),
    );
  }

  // ── RestartLevel ──────────────────────────────────────────────────────────

  void _onRestartLevel(RestartLevel event, Emitter<ListeningState> emit) =>
      emit(const ListeningInitial());

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Emits [ListeningGameComplete] immediately for snappy UI, then persists
  /// rewards in the background with up to [_kMaxSaveRetries] retries using
  /// exponential back-off so transient network errors don't silently lose XP.
  Future<void> _completeLevel(
    ListeningLoaded s,
    Emitter<ListeningState> emit,
  ) async {
    soundService.playLevelComplete();
    emit(
      const ListeningGameComplete(
        xpEarned: _kXpReward,
        coinsEarned: _kCoinReward,
        questCount: _kQuestionsPerLevel,
      ),
    );

    analytics.onLevelComplete(
      gameType: _currentGameType ?? '',
      level: _currentLevel ?? 0,
      xpEarned: _kXpReward,
      coinsEarned: _kCoinReward,
    );

    if (_currentGameType == null || _currentLevel == null) return;
    await _saveWithRetry(s.livesRemaining);
  }

  Future<void> _saveWithRetry(int starsEarned) async {
    for (int attempt = 1; attempt <= _kMaxSaveRetries; attempt++) {
      try {
        await Future.wait([
          updateUserRewards(
            UpdateUserRewardsParams(
              gameType: _currentGameType!,
              level: _currentLevel!,
              xpIncrease: _kXpReward,
              coinIncrease: _kCoinReward,
              starsEarned: starsEarned,
            ),
          ),
          updateCategoryStats(
            UpdateCategoryStatsParams(
              categoryId: _currentGameType!,
              isCorrect: true,
            ),
          ),
          awardBadge(_kListeningBadge),
        ]);
        return; // success
      } catch (e, stack) {
        debugPrint(
          '[ListeningBloc] Reward save attempt $attempt/$_kMaxSaveRetries '
          'failed: $e\n$stack',
        );
        if (attempt < _kMaxSaveRetries) {
          // Exponential back-off: 1 s, 2 s, 4 s
          await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
        }
      }
    }
    debugPrint('[ListeningBloc] All $_kMaxSaveRetries save attempts failed.');
  }
}

