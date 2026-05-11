import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import '../../domain/entities/vocabulary_quest.dart';
import '../../domain/usecases/get_vocabulary_quests.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/usecases/usecase.dart';

// --- EVENTS ---
abstract class VocabularyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchVocabularyQuests extends VocabularyEvent {
  final GameSubtype gameType;
  final int level;
  FetchVocabularyQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends VocabularyEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends VocabularyEvent {}

class RetryCurrentQuestion extends VocabularyEvent {}

class RestartLevel extends VocabularyEvent {}

class VocabularyHintUsed extends VocabularyEvent {}

class RestoreLife extends VocabularyEvent {}

class AddHint extends VocabularyEvent {
  final int count;
  AddHint(this.count);

  @override
  List<Object?> get props => [count];
}

// --- STATES ---
abstract class VocabularyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VocabularyInitial extends VocabularyState {}

class VocabularyLoading extends VocabularyState {}

class VocabularyLoaded extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  VocabularyQuest get currentQuest => quests[currentIndex];

  VocabularyLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [quests, currentIndex, livesRemaining, lastAnswerCorrect, hintUsed, wrongCount, isFinalFailure];

  VocabularyLoaded copyWith({
    List<VocabularyQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return VocabularyLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

class VocabularyError extends VocabularyState {
  final String message;
  final String? technicalError;
  VocabularyError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class VocabularyGameComplete extends VocabularyState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  VocabularyGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class VocabularyGameOver extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;
  VocabularyGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// --- BLOC ---
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

  String? currentGameType;
  int? currentLevel;

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
  }) : super(VocabularyInitial()) {
    on<FetchVocabularyQuests>(_onFetchQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetryQuestion);
    on<RestartLevel>(_onRestartLevel);
    on<VocabularyHintUsed>(_onUseHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
  }

  Future<void> _onFetchQuests(
    FetchVocabularyQuests event,
    Emitter<VocabularyState> emit,
  ) async {
    currentGameType = event.gameType.name;
    currentLevel = event.level;

    emit(VocabularyLoading());
    try {
      final quests = await getQuests(event.gameType.name, event.level);

      if (quests.isEmpty) {
        emit(
          VocabularyError(
            "We couldn't find any quests for this level yet.",
            technicalError: "Empty quest list returned for category: ${event.gameType.name}, level: ${event.level}",
          ),
        );
      } else {
        // Maintain JSON order and take 3 unique questions
        final uniqueQuests = <String, VocabularyQuest>{};
        for (var q in quests) {
          uniqueQuests[q.id] = q;
        }
        
        final list = uniqueQuests.values.toList();
        final limitedQuests = list.take(3).toList();

        emit(
          VocabularyLoaded(
            quests: limitedQuests,
            currentIndex: 0,
            livesRemaining: 3, // Standard 3 lives
          ),
        );
      }
    } catch (e) {
      emit(
        VocabularyError(
          "Failed to fetch quests. Please try again later.",
          technicalError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is VocabularyLoaded) {
      final s = state as VocabularyLoaded;
      if (s.livesRemaining <= 0) return;

      if (event.isCorrect) {
        await soundService.playCorrect();
        await hapticService.success();
        emit(s.copyWith(
          lastAnswerCorrect: true, 
          wrongCount: 0, 
          isFinalFailure: false
        ));
      } else {
        await soundService.playWrong();
        await hapticService.error();
        
        final newLives = s.livesRemaining - 1;
        final newWrongCount = s.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<VocabularyQuest> updatedQuests = s.quests;
        if (isFinal) {
          updatedQuests = List<VocabularyQuest>.from(s.quests);
          updatedQuests.add(s.currentQuest); // Mastery Loop: Review later
        }

        emit(s.copyWith(
          quests: updatedQuests,
          livesRemaining: newLives, 
          lastAnswerCorrect: false,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ));
      }
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is VocabularyLoaded) {
      final s = state as VocabularyLoaded;

      if (s.livesRemaining <= 0) {
        emit(VocabularyGameOver(
          quests: s.quests,
          currentIndex: s.currentIndex,
        ));
        return;
      }
      if (s.currentIndex >= s.quests.length - 1) {
        if (s.lastAnswerCorrect == true) {
          await soundService.playLevelComplete();
          
          // REWARD LOGIC: Fixed 10 XP and 10 Coins base as per Global App Logic
          const int totalXp = 10; 
          const int totalCoins = 10; 
          
          emit(
            VocabularyGameComplete(
              xpEarned: totalXp,
              coinsEarned: totalCoins,
              questCount: s.quests.length,
            ),
          );

          // PERSISTENCE
          if (currentGameType != null && currentLevel != null) {
            await updateUserRewards(
              UpdateUserRewardsParams(
                gameType: currentGameType!,
                level: currentLevel!,
                xpIncrease: totalXp,
                coinIncrease: totalCoins,
              ),
            );
            await updateCategoryStats(
              UpdateCategoryStatsParams(
                categoryId: currentGameType!,
                isCorrect: true,
              ),
            );
            await updateUnlockedLevel(
              UpdateUnlockedLevelParams(
                categoryId: currentGameType!,
                newLevel: currentLevel! + 1,
              ),
            );
            await awardBadge('vocabulary_master');
          }
        } else {
           // It was a wrong answer or no answer on the last quest
           // Stay on current index and clear lastAnswerCorrect so they can retry
           emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
        }
      } else if (s.lastAnswerCorrect == true || s.isFinalFailure) {
        // Only move to next if correct OR it was a second failure (re-queued)
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
        // This handles "TRY AGAIN" - reset the answer status to allow retry
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    }
  }

  void _onRetryQuestion(
    RetryCurrentQuestion event,
    Emitter<VocabularyState> emit,
  ) {
    if (state is VocabularyLoaded) {
      final s = state as VocabularyLoaded;
      emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
    }
  }

  Future<void> _onRestartLevel(RestartLevel event, Emitter<VocabularyState> emit) async {
    if (currentGameType != null && currentLevel != null) {
      add(FetchVocabularyQuests(
        gameType: GameSubtype.values.firstWhere((e) => e.name == currentGameType),
        level: currentLevel!,
      ));
    } else {
      emit(VocabularyInitial());
    }
  }

  Future<void> _onUseHint(
    VocabularyHintUsed event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is VocabularyLoaded) {
      final s = state as VocabularyLoaded;
      if (s.hintUsed) return;

      final result = await useHint(NoParams());
      result.fold(
        (failure) => null,
        (_) {
          emit(s.copyWith(hintUsed: true));
          hapticService.selection();
        },
      );
    }
  }

  void _onRestoreLife(RestoreLife event, Emitter<VocabularyState> emit) {
    if (state is VocabularyGameOver) {
      final s = state as VocabularyGameOver;
      emit(
        VocabularyLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1, // Revive gives 1 life
          lastAnswerCorrect: null,
          hintUsed: false,
        ),
      );
    }
  }

  void _onAddHint(AddHint event, Emitter<VocabularyState> emit) {}
}

