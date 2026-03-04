import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxai_quest/features/speaking/domain/usecases/get_speaking_quest.dart';
import 'package:voxai_quest/core/usecases/usecase.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/usecases/get_grammar_quest.dart';
import '../../domain/usecases/preload_grammar_quest.dart';
import '../../../auth/domain/usecases/update_user_coins.dart';
import '../../../auth/domain/usecases/update_user_rewards.dart';
import '../../../auth/domain/usecases/update_category_stats.dart';
import '../../../auth/domain/usecases/update_unlocked_level.dart';
import '../../../auth/domain/usecases/award_badge.dart';
import '../../../auth/domain/usecases/use_hint.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';

import 'grammar_event.dart';
import 'grammar_state.dart';

export 'grammar_event.dart';
export 'grammar_state.dart';

class GrammarBloc extends Bloc<GrammarEvent, GrammarState> {
  final GetGrammarQuest getQuest;
  final PreloadGrammarQuest preloadQuest;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;

  GameSubtype? currentGameType;
  int? currentLevel;

  GrammarBloc({
    required this.getQuest,
    required this.preloadQuest,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
  }) : super(GrammarInitial()) {
    on<FetchGrammarQuests>(_onFetchGrammarQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<GrammarHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RestartLevel>(_onRestartLevel);
    on<PreloadGrammarBatch>(_onPreloadBatch);
  }

  Future<void> _onFetchGrammarQuests(
    FetchGrammarQuests event,
    Emitter<GrammarState> emit,
  ) async {
    currentGameType = event.gameType;
    currentLevel = event.level;

    emit(GrammarLoading());

    final result = await getQuest(
      QuestParams(gameType: event.gameType, level: event.level),
    );

    result.fold((failure) => emit(GrammarError(failure.message)), (quests) {
      if (quests.isEmpty) {
        emit(GrammarError("Check back later for new quests!"));
        return;
      }

      // Industrial standard: check if we should preload next batch
      // Trigger preloading if level ends in 9
      if (event.level % 10 == 9) {
        add(PreloadGrammarBatch(gameType: event.gameType, level: event.level));
      }

      // Ensure 3 questions per level
      final limitedQuests = quests.take(3).toList();
      emit(
        GrammarLoaded(
          quests: limitedQuests,
          currentIndex: 0,
          livesRemaining: 3,
        ),
      );
    });
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<GrammarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GrammarLoaded) return;

    int newLives = currentState.livesRemaining;
    if (!event.isCorrect) {
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
        GrammarGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<GrammarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GrammarLoaded) return;

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

        final totalXp = currentState.quests.fold(
          0,
          (sum, q) => sum + q.xpReward,
        );
        final totalCoins = currentState.quests.fold(
          0,
          (sum, q) => sum + q.coinReward,
        );

        emit(GrammarGameComplete(xpEarned: totalXp, coinsEarned: totalCoins));

        // Persistence
        if (currentGameType != null && currentLevel != null) {
          await updateUserCoins(UpdateUserCoinsParams(amountChange: totalXp));
          await updateUserRewards(
            UpdateUserRewardsParams(
              gameType: currentGameType!.name,
              level: currentLevel!,
              xpIncrease: totalXp,
              coinIncrease: totalCoins,
            ),
          );
          await updateCategoryStats(
            UpdateCategoryStatsParams(
              categoryId: currentGameType!.name,
              isCorrect: true,
            ),
          );
          await updateUnlockedLevel(
            UpdateUnlockedLevelParams(
              categoryId: currentGameType!.name,
              newLevel: currentLevel! + 1,
            ),
          );
          await awardBadge('grammar_master');
        }
      }
    } else {
      emit(currentState.copyWith(lastAnswerCorrect: null));
    }
  }

  Future<void> _onHintUsed(
    GrammarHintUsed event,
    Emitter<GrammarState> emit,
  ) async {
    if (state is GrammarLoaded) {
      final s = state as GrammarLoaded;
      if (s.hintUsed) return;

      final result = await useHint(NoParams());
      result.fold(
        (failure) {}, // Handle failure if needed
        (_) {
          emit(s.copyWith(hintUsed: true));
          hapticService.selection();
        },
      );
    }
  }

  void _onRestoreLife(RestoreLife event, Emitter<GrammarState> emit) {
    if (state is GrammarGameOver) {
      final s = state as GrammarGameOver;
      emit(
        GrammarLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          lastAnswerCorrect: null,
          hintUsed: false,
        ),
      );
    }
  }

  void _onRestartLevel(RestartLevel event, Emitter<GrammarState> emit) {
    emit(GrammarInitial());
  }

  Future<void> _onPreloadBatch(
    PreloadGrammarBatch event,
    Emitter<GrammarState> emit,
  ) async {
    // Fire and forget preloading in background
    await preloadQuest(
      QuestParams(gameType: event.gameType, level: event.level),
    );
  }
}
