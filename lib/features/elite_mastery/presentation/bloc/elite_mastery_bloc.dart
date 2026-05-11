import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import '../../domain/entities/elite_mastery_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../domain/usecases/get_elite_mastery_quests.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';

part 'elite_mastery_event.dart';
part 'elite_mastery_state.dart';

class EliteMasteryBloc extends Bloc<EliteMasteryEvent, EliteMasteryState> {
  final GetEliteMasteryQuests getQuests;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final UseHint useHint;
  final SoundService soundService;
  final HapticService hapticService;

  GameSubtype? currentGameType;
  int? currentLevel;

  EliteMasteryBloc({
    required this.getQuests,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.useHint,
    required this.soundService,
    required this.hapticService,
  }) : super(EliteMasteryInitial()) {
    on<FetchEliteMasteryQuests>((event, emit) async {
      currentGameType = event.gameType;
      currentLevel = event.level;
      emit(EliteMasteryLoading());

      // Fetch quests through the usecase (which uses AssetQuestService LRU cache)
      final result = await getQuests(GetEliteMasteryQuestParams(gameType: event.gameType, level: event.level));
      result.fold(
        (failure) => emit(EliteMasteryError(failure.message)),
        (quests) {
          if (quests.isEmpty) {
            emit(EliteMasteryError("No quests found for this level."));
          } else {
            // Take only 3 questions per level for exact elite experience
            final levelQuests = quests.take(3).toList();
            emit(EliteMasteryLoaded(
              quests: levelQuests,
              currentIndex: 0,
              livesRemaining: 3,
            ));
          }
        },
      );
    });

    on<SubmitEliteAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is EliteMasteryLoaded && currentState.livesRemaining > 0) {
        if (!event.isCorrect) {
          final newLives = currentState.livesRemaining - 1;
          final newWrongCount = currentState.wrongCount + 1;
          bool isFinal = newWrongCount >= 2;

          List<EliteMasteryQuest> updatedQuests = currentState.quests;
          if (isFinal) {
            updatedQuests = List<EliteMasteryQuest>.from(currentState.quests);
            updatedQuests.add(currentState.currentQuest);
          }

          await soundService.playWrong();
          await hapticService.error();

          emit(currentState.copyWith(
            livesRemaining: newLives,
            lastAnswerCorrect: false,
            quests: updatedQuests,
            wrongCount: isFinal ? 0 : newWrongCount,
            isFinalFailure: isFinal || newLives <= 0,
          ));
        } else {
          await soundService.playCorrect();
          await hapticService.success();
          emit(currentState.copyWith(
            lastAnswerCorrect: true,
            wrongCount: 0,
            isFinalFailure: false,
          ));
        }
      }
    });

    on<NextEliteQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is EliteMasteryLoaded) {
        if (currentState.livesRemaining <= 0) {
          emit(EliteMasteryGameOver(
            quests: currentState.quests,
            currentIndex: currentState.currentIndex,
          ));
          return;
        }
        // If correct, advance. If wrong but re-queued, also advance if it wasn't the last.
        // Actually, for re-queueing, we ALWAYS advance if not complete.
        if (currentState.currentIndex + 1 < currentState.quests.length) {
          if (currentState.lastAnswerCorrect == true || currentState.isFinalFailure) {
            emit(currentState.copyWith(
              currentIndex: currentState.currentIndex + 1,
              resetLastAnswer: true,
              isHintVisible: false,
              isHintUsed: false,
              wrongCount: 0,
              isFinalFailure: false,
            ));
          } else {
            // First-time wrong answer, stay and retry
            emit(currentState.copyWith(lastAnswerCorrect: null, isHintVisible: false));
          }
        } else if (currentState.lastAnswerCorrect == true) {
          // Level Completed!
          soundService.playLevelComplete();
          
          // Calculate total rewards
          const int finalXp = 10;
          const int finalCoins = 10;

          emit(EliteMasteryGameComplete(xpEarned: finalXp, coinsEarned: finalCoins));

          if (currentGameType != null && currentLevel != null) {
            await updateUserRewards(UpdateUserRewardsParams(
              gameType: currentGameType!.name,
              level: currentLevel!,
              xpIncrease: finalXp,
              coinIncrease: finalCoins,
            ));
            await updateCategoryStats(UpdateCategoryStatsParams(
              categoryId: currentGameType!.name,
              isCorrect: true,
            ));
            await updateUnlockedLevel(UpdateUnlockedLevelParams(
              categoryId: currentGameType!.name,
              newLevel: currentLevel! + 1,
            ));
          }
        } else {
          // Wrong answer on the very last quest
          emit(currentState.copyWith(lastAnswerCorrect: null, isHintVisible: false));
        }
      }
    });

    on<ShowEliteHint>((event, emit) async {
      final currentState = state;
      if (currentState is EliteMasteryLoaded) {
        await hapticService.selection();
        emit(currentState.copyWith(isHintVisible: true));
      }
    });

    on<MarkEliteHintUsed>((event, emit) async {
      final currentState = state;
      if (currentState is EliteMasteryLoaded) {
        await useHint(NoParams());
        emit(currentState.copyWith(isHintUsed: true));
      }
    });

    on<AddLifeFromAd>((event, emit) {
      final currentState = state;
      if (state is EliteMasteryGameOver) {
        final s = state as EliteMasteryGameOver;
        emit(EliteMasteryLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          lastAnswerCorrect: null,
          isHintVisible: false,
        ));
      } else if (currentState is EliteMasteryLoaded) {
         emit(currentState.copyWith(livesRemaining: currentState.livesRemaining + 1));
      }
    });

    on<RestoreEliteLife>((event, emit) {
      if (state is EliteMasteryGameOver) {
        final s = state as EliteMasteryGameOver;
        emit(EliteMasteryLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          lastAnswerCorrect: null,
        ));
      }
    });

    on<EliteTutorPass>((event, emit) async {
      final currentState = state;
      if (currentState is EliteMasteryLoaded) {
        // Restore the life lost in the previous attempt
        int newLives = currentState.livesRemaining + 1;
        if (newLives > 3) newLives = 3; // Cap at max
        
        final updatedQuests = List<EliteMasteryQuest>.from(currentState.quests);
        if (updatedQuests.length > 3) updatedQuests.removeLast();
        
        await soundService.playCorrect();
        await hapticService.success();
        
        emit(currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: true,
          quests: updatedQuests,
        ));
      } else if (currentState is EliteMasteryGameOver) {
        // Restore from Game Over
        await soundService.playCorrect();
        await hapticService.success();
        
        emit(EliteMasteryLoaded(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
          livesRemaining: 1, // Start with 1 life after rescue
          lastAnswerCorrect: true,
        ));
      }
    });
  }
}
