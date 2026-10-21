import 'package:vowl/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:vowl/features/reading/presentation/constants/reading_constants.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../domain/usecases/get_reading_quest.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import 'reading_event.dart';
import 'reading_state.dart';

// Re-export so existing `import 'reading_bloc.dart'` call-sites resolve events
// and states without any changes.
export 'reading_event.dart';
export 'reading_state.dart';

class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  final GetReadingQuest getQuest;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  /// Set during [FetchReadingQuests]; consumed by the level-completion save.
  String? currentGameType;
  int? currentLevel;

  ReadingBloc({
    required this.getQuest,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(const ReadingInitial()) {
    on<RetryCurrentQuestion>(_onRetryCurrentQuestion);
    on<FetchReadingQuests>(_onFetchReadingQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<ReadingHintUsed>(_onReadingHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RestartLevel>(_onRestartLevel);
    on<ReadingSpeakConfirmed>(_onSpeakConfirmed);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onSpeakConfirmed(
    ReadingSpeakConfirmed event,
    Emitter<ReadingState> emit,
  ) {
    // Per strict app architecture: verbal confirmations verify speech accuracy only
    // and never award mid-game coins. Rewards (5 XP + 10 Coins) are awarded strictly
    // upon level completion via updateUserRewards.
  }

  void _onRetryCurrentQuestion(
    RetryCurrentQuestion event,
    Emitter<ReadingState> emit,
  ) {
    if (state is ReadingLoaded) {
      emit(
        (state as ReadingLoaded).copyWith(
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
        ),
      );
    }
  }

  Future<void> _onFetchReadingQuests(
    FetchReadingQuests event,
    Emitter<ReadingState> emit,
  ) async {
    currentGameType = event.gameType is GameSubtype
        ? (event.gameType as GameSubtype).name
        : event.gameType.toString();
    currentLevel = event.level;

    emit(const ReadingLoading());

    try {
      final GameSubtype subtype = event.gameType is GameSubtype
          ? event.gameType
          : GameSubtype.fromString(
              event.gameType.toString(),
              fallback: GameSubtype.readAndAnswer,
            );

      final result = await getQuest(
        GetReadingQuestParams(gameType: subtype, level: event.level),
      );

      result.fold(
        (failure) => emit(
          ReadingError(failure.message, technicalError: failure.toString()),
        ),
        (quests) {
          if (quests.isEmpty) {
            emit(
              ReadingError(
                'No comprehension quests found.',
                technicalError:
                    'Empty list for $currentGameType, Level $currentLevel',
              ),
            );
          } else {
            emit(
              ReadingLoaded(
                quests: quests
                    .take(ReadingGameConfig.maxQuestsPerSession)
                    .toList(),
                currentIndex: 0,
                livesRemaining: ReadingGameConfig.initialLives,
              ),
            );
          }
        },
      );
    } catch (e) {
      // logger?.error('FetchReadingQuests failed', error: e, stackTrace: st);
      emit(
        ReadingError(
          'Failed to fetch reading quests.',
          technicalError: e.toString(),
        ),
      );
    }
  }

  /// Processes a player answer. Emits exactly once per call.
  ///
  /// The guard [lastAnswerCorrect] != null prevents double-tap processing.
  /// BLoC serialises events, so by the time a queued second [SubmitAnswer]
  /// is dequeued, the state already has a non-null value and the guard exits.
  void _onSubmitAnswer(SubmitAnswer event, Emitter<ReadingState> emit) {
    final s = state;
    if (s is! ReadingLoaded ||
        s.livesRemaining <= 0 ||
        s.answerStatus.isAnswered) {
      return;
    }

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
      final isFinal =
          newWrongCount >= ReadingGameConfig.wrongAnswersBeforeFinal;

      emit(
        s.copyWith(
          quests: isFinal ? [...s.quests, s.currentQuest] : s.quests,
          livesRemaining: newLives,
          answerStatus: AnswerStatus.incorrect,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<ReadingState> emit,
  ) async {
    final s = state;
    if (s is! ReadingLoaded) return;

    if (s.livesRemaining <= 0) {
      emit(ReadingGameOver(quests: s.quests, currentIndex: s.currentIndex));
      return;
    }

    final isLastQuestion = s.currentIndex + 1 >= s.quests.length;

    if (!isLastQuestion) {
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
        emit(
          s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false),
        );
      }
      return;
    }

    if (s.answerStatus == AnswerStatus.correct) {
      // 1. Instant UI feedback
      emit(
        ReadingGameComplete(
          xpEarned: ReadingGameConfig.xpPerLevel,
          coinsEarned: ReadingGameConfig.coinsPerLevel,
          questCount: s.quests.length,
        ),
      );

      // 2. Background persistence (fire-and-forget, parallelized, 0ms lag)
      _persistLevelCompletion(s.livesRemaining);
    } else {
      emit(s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false));
    }
  }

  Future<void> _onReadingHintUsed(
    ReadingHintUsed event,
    Emitter<ReadingState> emit,
  ) async {
    final s = state;
    if (s is! ReadingLoaded || s.hintUsed) return;
    final result = await useHint(NoParams());
    if (result.isRight()) {
      emit(s.copyWith(hintUsed: true));
      hapticService.selection();
    }
  }

  void _onRestoreLife(RestoreLife event, Emitter<ReadingState> emit) {
    final s = state;
    if (s is! ReadingGameOver) return;
    emit(
      ReadingLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
      ),
    );
  }

  void _onRestartLevel(RestartLevel event, Emitter<ReadingState> emit) {
    emit(const ReadingInitial());
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Persists XP, coins, stats, and badge after a successful level completion.
  ///
  /// Called AFTER [ReadingGameComplete] is emitted — a failure here never
  /// affects the UI. Persistence is executed immediately in parallel via
  /// [Future.wait] without gating on network pings; Firestore and repository
  /// layers handle offline caching and retry transparently.
  void _persistLevelCompletion(int starsEarned) {
    final gameType = currentGameType ??
        (state is ReadingLoaded && (state as ReadingLoaded).quests.isNotEmpty
            ? (state as ReadingLoaded).quests.first.subtype?.name
            : null);
    final level = currentLevel;
    if (gameType == null || level == null) return;

    Future.wait([
      updateUserRewards(
        UpdateUserRewardsParams(
          gameType: gameType,
          level: level,
          xpIncrease: ReadingGameConfig.xpPerLevel,
          coinIncrease: ReadingGameConfig.coinsPerLevel,
          starsEarned: starsEarned,
        ),
      ).catchError((_) => const Right<Failure, void>(null)),
      updateCategoryStats(
        UpdateCategoryStatsParams(
          categoryId: gameType,
          isCorrect: true,
        ),
      ).catchError((_) => const Right<Failure, void>(null)),
      awardBadge(
        'reading_master',
      ).catchError((_) => const Right<Failure, void>(null)),
    ], eagerError: false);
  }
}
