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
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onRetryCurrentQuestion(
    RetryCurrentQuestion event,
    Emitter<ReadingState> emit,
  ) {
    if (state is ReadingLoaded) {
      emit(
        (state as ReadingLoaded).copyWith(
          lastAnswerCorrect: null,
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
        s.lastAnswerCorrect != null) {
      return;
    }

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
      final isFinal =
          newWrongCount >= ReadingGameConfig.wrongAnswersBeforeFinal;

      emit(
        s.copyWith(
          quests: isFinal ? [...s.quests, s.currentQuest] : s.quests,
          livesRemaining: newLives,
          lastAnswerCorrect: false,
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
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
      return;
    }

    if (s.lastAnswerCorrect == true) {
      soundService.playLevelComplete();
      emit(
        ReadingGameComplete(
          xpEarned: ReadingGameConfig.xpPerLevel,
          coinsEarned: ReadingGameConfig.coinsPerLevel,
          questCount: s.quests.length,
        ),
      );
      await _persistLevelCompletion(s.livesRemaining);
    } else {
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
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
  /// affects the UI. Offline guard prevents pointless requests.
  Future<void> _persistLevelCompletion(int starsEarned) async {
    if (currentGameType == null || currentLevel == null) return;

    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      //  Enqueue for offline retry via a PendingRewardsQueue service.
      return;
    }

    try {
      await Future.wait([
        updateUserRewards(
          UpdateUserRewardsParams(
            gameType: currentGameType!,
            level: currentLevel!,
            xpIncrease: ReadingGameConfig.xpPerLevel,
            coinIncrease: ReadingGameConfig.coinsPerLevel,
            starsEarned: starsEarned,
          ),
        ),
        updateCategoryStats(
          UpdateCategoryStatsParams(
            categoryId: currentGameType!,
            isCorrect: true,
          ),
        ),
        awardBadge('reading_master'),
      ]);
    } catch (e) {
      // logger?.error('Level completion save failed', error: e, stackTrace: st);
    }
  }
}
