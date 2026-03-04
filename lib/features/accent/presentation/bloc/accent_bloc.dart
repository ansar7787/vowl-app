import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../domain/entities/accent_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/usecases/get_accent_quest.dart';
import '../../domain/usecases/preload_accent_quest.dart';
import '../../domain/usecases/clear_accent_quest_cache.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';

part 'accent_event.dart';
part 'accent_state.dart';

class AccentBloc extends Bloc<AccentEvent, AccentState> {
  final GetAccentQuest getQuest;
  final PreloadAccentQuest preloadQuest;
  final ClearAccentQuestCache clearCache;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  String? currentGameType;
  int? currentLevel;

  AccentBloc({
    required this.getQuest,
    required this.preloadQuest,
    required this.clearCache,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(AccentInitial()) {
    on<FetchAccentQuests>((event, emit) async {
      currentGameType = event.gameType.name;
      currentLevel = event.level;

      // Clear cache if starting a new game level 1 to pick up latest JSON changes
      if (currentLevel == 1) {
        await clearCache(NoParams());
      }

      emit(AccentLoading());
      try {
        final result = await getQuest(
          GetAccentQuestParams(gameType: event.gameType, level: currentLevel!),
        );

        result.fold((failure) => emit(AccentError(failure.message)), (quests) {
          if (quests.isEmpty) {
            emit(
              AccentError("We couldn't find any quests for this level yet."),
            );
            return;
          }

          final limitedQuests = quests.take(3).toList();
          emit(
            AccentLoaded(
              quests: limitedQuests,
              currentIndex: 0,
              livesRemaining: 3,
              gameType: event.gameType,
              level: currentLevel!,
            ),
          );
        });

        if (currentLevel! % 10 == 9) {
          add(
            PreloadBatch(gameType: event.gameType, currentLevel: currentLevel!),
          );
        }
      } catch (e) {
        emit(AccentError("Failed to fetch quests: $e"));
      }
    });

    on<PreloadBatch>((event, emit) async {
      try {
        await preloadQuest(
          PreloadAccentQuestParams(
            gameType: event.gameType,
            level: event.currentLevel,
          ),
        );
      } catch (e) {
        // Silently fail for pre-loading
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! AccentLoaded) return;

      // Handle the null case for resetting feedback state (retries)
      if (event.isCorrect == null) {
        emit(currentState.copyWith(lastAnswerCorrect: null));
        return;
      }

      int newLives = currentState.livesRemaining;
      if (event.isCorrect == false) {
        newLives--;
        await soundService.playWrong();
        await hapticService.error();
      } else {
        await soundService.playCorrect();
        await hapticService.success();
      }

      emit(
        currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: event.isCorrect,
        ),
      );

      if (newLives <= 0) {
        emit(
          AccentGameOver(
            quests: currentState.quests,
            currentIndex: currentState.currentIndex,
            gameType: currentState.gameType,
            level: currentState.level,
          ),
        );
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! AccentLoaded) return;

      if (currentState.lastAnswerCorrect == true) {
        if (currentState.currentIndex + 1 < currentState.quests.length) {
          emit(
            currentState.copyWith(
              currentIndex: currentState.currentIndex + 1,
              lastAnswerCorrect: null,
              hintUsed: false,
            ),
          );
        } else {
          await soundService.playLevelComplete();
          emit(
            AccentGameComplete(
              xpEarned: 5,
              coinsEarned: 10,
              lastState: currentState,
            ),
          );

          if (currentGameType != null && currentLevel != null) {
            await updateUserRewards(
              UpdateUserRewardsParams(
                gameType: currentGameType!,
                level: currentLevel!,
                xpIncrease: 5,
                coinIncrease: 10,
              ),
            );
            await updateCategoryStats(
              UpdateCategoryStatsParams(
                categoryId: currentGameType!,
                isCorrect: true,
              ),
            );
            await awardBadge('accent_master');
            await updateUnlockedLevel(
              UpdateUnlockedLevelParams(
                categoryId: currentGameType!,
                newLevel: currentLevel! + 1,
              ),
            );
          }
        }
      } else {
        emit(currentState.copyWith(lastAnswerCorrect: null));
      }
    });

    on<AccentHintUsed>((event, emit) async {
      if (state is AccentLoaded) {
        final s = state as AccentLoaded;
        if (s.hintUsed) return;

        final result = await useHint(NoParams());
        if (result.isRight()) {
          emit(s.copyWith(hintUsed: true));
          hapticService.selection();
        }
      }
    });

    on<RestoreLife>((event, emit) {
      if (state is AccentGameOver) {
        final s = state as AccentGameOver;
        emit(
          AccentLoaded(
            quests: s.quests,
            currentIndex: s.currentIndex,
            livesRemaining: 1,
            lastAnswerCorrect: null,
            hintUsed: false,
            gameType: s.gameType,
            level: s.level,
          ),
        );
      }
    });

    on<RestartLevel>((event, emit) {
      emit(AccentInitial());
    });
  }
}
