import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../domain/entities/accent_quest.dart';
import '../../domain/usecases/get_accent_quest.dart';
import '../../domain/usecases/preload_accent_quest.dart';
import '../../domain/usecases/clear_accent_quest_cache.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';

// --- EVENTS ---
abstract class AccentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchAccentQuests extends AccentEvent {
  final GameSubtype gameType;
  final int level;
  FetchAccentQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends AccentEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends AccentEvent {}

class RestartLevel extends AccentEvent {}

class AccentHintUsed extends AccentEvent {}

class RetryCurrentQuestion extends AccentEvent {}

class RestoreLife extends AccentEvent {}

class PreloadBatch extends AccentEvent {
  final GameSubtype gameType;
  final int currentLevel;
  PreloadBatch({required this.gameType, required this.currentLevel});

  @override
  List<Object?> get props => [gameType, currentLevel];
}

class AccentTutorPass extends AccentEvent {}

// --- STATES ---
abstract class AccentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AccentInitial extends AccentState {}

class AccentLoading extends AccentState {}

class AccentLoaded extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final GameSubtype gameType;
  final int level;
  final int wrongCount;
  final bool isFinalFailure;

  AccentQuest get currentQuest => quests[currentIndex];

  AccentLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    required this.gameType,
    required this.level,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [quests, currentIndex, livesRemaining, lastAnswerCorrect, hintUsed, gameType, level, wrongCount, isFinalFailure];

  AccentLoaded copyWith({
    List<AccentQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    GameSubtype? gameType,
    int? level,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return AccentLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

class AccentError extends AccentState {
  final String message;
  final String? technicalError;
  AccentError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class AccentGameComplete extends AccentState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  final AccentLoaded lastState;
  AccentGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
    required this.lastState,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount, lastState];
}

class AccentGameOver extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;
  AccentGameOver({required this.quests, required this.currentIndex, required this.gameType, required this.level});

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}

// --- BLOC ---
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

      emit(AccentLoading());

      final result = await getQuest(
        GetAccentQuestParams(gameType: event.gameType, level: event.level),
      );

      result.fold(
        (failure) => emit(AccentError(failure.message)),
        (quests) {
          if (quests.isEmpty) {
            emit(AccentError("No quests available for this level."));
            return;
          }

          final limitedQuests = quests.take(3).toList();
          emit(
            AccentLoaded(
              quests: limitedQuests,
              currentIndex: 0,
              livesRemaining: 3,
              gameType: event.gameType,
              level: event.level,
            ),
          );
        },
      );
    });

    on<RetryCurrentQuestion>((event, emit) {
      if (state is AccentLoaded) {
        final s = state as AccentLoaded;
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! AccentLoaded || currentState.livesRemaining <= 0) return;

      if (!event.isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<AccentQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<AccentQuest>.from(currentState.quests);
          updatedQuests.add(currentState.currentQuest); // Mastery Loop
        }

        await soundService.playWrong();
        await hapticService.error();

        emit(
          currentState.copyWith(
            livesRemaining: newLives,
            lastAnswerCorrect: false,
            quests: updatedQuests,
            wrongCount: isFinal ? 0 : newWrongCount,
            isFinalFailure: isFinal || newLives <= 0,
          ),
        );
      } else {
        await soundService.playCorrect();
        await hapticService.success();
        emit(
          currentState.copyWith(
            lastAnswerCorrect: true,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! AccentLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(AccentGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
          gameType: currentState.gameType,
          level: currentState.level,
        ));
        return;
      }

      if (currentState.currentIndex + 1 < currentState.quests.length) {
        if (currentState.lastAnswerCorrect == true || currentState.isFinalFailure) {
          emit(
            currentState.copyWith(
              currentIndex: currentState.currentIndex + 1,
              lastAnswerCorrect: null,
              hintUsed: false,
              wrongCount: 0,
              isFinalFailure: false,
            ),
          );
        } else {
          // First-time wrong answer, stay and retry
          emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
        }
      } else if (currentState.lastAnswerCorrect == true) {
        await soundService.playLevelComplete();
        
        const int totalXp = 10;
        const int totalCoins = 10;

        emit(AccentGameComplete(
          xpEarned: totalXp,
          coinsEarned: totalCoins,
          questCount: currentState.quests.length,
          lastState: currentState,
        ));

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
          await awardBadge('accent_master');
        }
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
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

    on<AccentTutorPass>((event, emit) async {
      final currentState = state;
      if (currentState is AccentLoaded) {
        int newLives = currentState.livesRemaining + 1;
        if (newLives > 3) newLives = 3;

        final updatedQuests = List<AccentQuest>.from(currentState.quests);
        if (updatedQuests.length > 3) updatedQuests.removeLast();

        await soundService.playCorrect();
        await hapticService.success();

        emit(currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: true,
          quests: updatedQuests,
        ));
      } else if (currentState is AccentGameOver) {
        // Restore from Game Over
        await soundService.playCorrect();
        await hapticService.success();
        
        emit(AccentLoaded(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
          livesRemaining: 1, // Start with 1 life after rescue
          lastAnswerCorrect: true,
          gameType: currentState.gameType,
          level: currentState.level,
        ));
      }
    });

    on<RestartLevel>((event, emit) {
      emit(AccentInitial());
    });
  }
}
