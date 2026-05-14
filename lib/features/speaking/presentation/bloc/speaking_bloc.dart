import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../domain/entities/speaking_quest.dart';
import '../../domain/usecases/get_speaking_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';

// --- EVENTS ---
abstract class SpeakingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchSpeakingQuests extends SpeakingEvent {
  final dynamic gameType;
  final int level;
  FetchSpeakingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends SpeakingEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends SpeakingEvent {}

class RestartLevel extends SpeakingEvent {}

class SpeakingHintUsed extends SpeakingEvent {}

class RetryCurrentQuestion extends SpeakingEvent {}

class RestoreLife extends SpeakingEvent {}

class AddHint extends SpeakingEvent {
  final int count;
  AddHint(this.count);

  @override
  List<Object?> get props => [count];
}

class SpeakingTutorPass extends SpeakingEvent {}

// --- STATES ---
abstract class SpeakingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SpeakingInitial extends SpeakingState {}

class SpeakingLoading extends SpeakingState {}

class SpeakingLoaded extends SpeakingState {
  final List<SpeakingQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  SpeakingQuest get currentQuest => quests[currentIndex];

  SpeakingLoaded({
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

  SpeakingLoaded copyWith({
    List<SpeakingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return SpeakingLoaded(
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

class SpeakingError extends SpeakingState {
  final String message;
  final String? technicalError;
  SpeakingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class SpeakingGameComplete extends SpeakingState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  SpeakingGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class SpeakingGameOver extends SpeakingState {
  final List<SpeakingQuest> quests;
  final int currentIndex;
  SpeakingGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// --- BLOC ---
class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final GetSpeakingQuest getQuest;
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

  SpeakingBloc({
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
  }) : super(SpeakingInitial()) {
    on<FetchSpeakingQuests>((event, emit) async {
      final GameSubtype subtype = event.gameType is GameSubtype
          ? event.gameType
          : GameSubtype.values.firstWhere(
              (s) => s.name == event.gameType.toString(),
              orElse: () => GameSubtype.repeatSentence,
            );
      currentGameType = subtype.name;
      currentLevel = event.level;

      emit(SpeakingLoading());

      final result = await getQuest(
        QuestParams(gameType: subtype, level: event.level),
      );

      result.fold(
        (failure) => emit(SpeakingError(
          failure.message,
          technicalError: "Usecase Failure: ${failure.toString()}",
        )),
        (quests) {
          if (quests.isEmpty) {
            emit(SpeakingError(
              "Check back later for new quests!",
              technicalError: "Empty quest list for $currentGameType, Level $currentLevel",
            ));
            return;
          }

          // ENSURE STICKY 3 QUESTIONS PER LEVEL
          final limitedQuests = quests.take(3).toList();
          emit(
            SpeakingLoaded(
              quests: limitedQuests,
              currentIndex: 0,
              livesRemaining: 3,
            ),
          );
        },
      );
    });

    on<RestartLevel>((event, emit) {
      emit(SpeakingInitial());
    });

    on<RetryCurrentQuestion>((event, emit) {
      if (state is SpeakingLoaded) {
        final s = state as SpeakingLoaded;
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<SpeakingHintUsed>(_onUseHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
    on<SpeakingTutorPass>(_onTutorPass);

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! SpeakingLoaded || currentState.livesRemaining <= 0) return;

      if (!event.isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<SpeakingQuest> updatedQuests = List.from(currentState.quests);
        if (isFinal) {
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
      if (currentState is! SpeakingLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(SpeakingGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
        ));
        return;
      }

      // Move to next question if it was a success OR a final failure (since it's re-queued)
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
        // We only complete the level if the LAST question in the queue was answered correctly
        soundService.playLevelComplete();
        
        // Calculate rewards
        const int totalXp = 10;
        const int totalCoins = 10;

        // 1. Immediate UI Feedback
        emit(SpeakingGameComplete(
          xpEarned: totalXp,
          coinsEarned: totalCoins,
          questCount: currentState.quests.length,
        ));

        // 2. Background Save
        if (currentGameType != null && currentLevel != null) {
          await Future.wait([
            updateUserRewards(
              UpdateUserRewardsParams(
                gameType: currentGameType!,
                level: currentLevel!,
                xpIncrease: 10,
                coinIncrease: 10,
              ),
            ),
            updateCategoryStats(
              UpdateCategoryStatsParams(
                categoryId: currentGameType!,
                isCorrect: true,
              ),
            ),
            updateUnlockedLevel(
              UpdateUnlockedLevelParams(
                categoryId: currentGameType!,
                newLevel: currentLevel! + 1,
              ),
            ),
            awardBadge('speaking_master'),
          ]);
        }
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });
  }

  Future<void> _onUseHint(
    SpeakingHintUsed event,
    Emitter<SpeakingState> emit,
  ) async {
    if (state is SpeakingLoaded) {
      final s = state as SpeakingLoaded;
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

  void _onRestoreLife(RestoreLife event, Emitter<SpeakingState> emit) {
    if (state is SpeakingGameOver) {
      final s = state as SpeakingGameOver;
      emit(
        SpeakingLoaded(
          quests: s.quests,
          currentIndex: s.currentIndex,
          livesRemaining: 1,
          lastAnswerCorrect: null,
          hintUsed: false,
        ),
      );
    }
  }

  void _onAddHint(AddHint event, Emitter<SpeakingState> emit) {
    // Logic to update user count if needed
  }

  void _onTutorPass(SpeakingTutorPass event, Emitter<SpeakingState> emit) async {
    final currentState = state;
    if (currentState is SpeakingLoaded) {
      int newLives = currentState.livesRemaining + 1;
      if (newLives > 3) newLives = 3;

      final updatedQuests = List<SpeakingQuest>.from(currentState.quests);
      if (updatedQuests.length > 3) updatedQuests.removeLast();

      await soundService.playCorrect();
      await hapticService.success();

      emit(currentState.copyWith(
        livesRemaining: newLives,
        lastAnswerCorrect: true,
        quests: updatedQuests,
      ));
    } else if (currentState is SpeakingGameOver) {
      // Restore from Game Over
      await soundService.playCorrect();
      await hapticService.success();
      
      emit(SpeakingLoaded(
        quests: currentState.quests,
        currentIndex: currentState.currentIndex,
        livesRemaining: 1, // Start with 1 life after rescue
        lastAnswerCorrect: true,
      ));
    }
  }
}
