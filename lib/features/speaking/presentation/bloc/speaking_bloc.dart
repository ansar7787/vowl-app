import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart';

// --- EVENTS ---
abstract class SpeakingEvent extends Equatable {
  const SpeakingEvent();

  @override
  List<Object?> get props => [];
}

class FetchSpeakingQuests extends SpeakingEvent {
  final Object gameType;
  final int level;

  const FetchSpeakingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends SpeakingEvent {
  final bool isCorrect;
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends SpeakingEvent {
  const NextQuestion();
}

class RestartLevel extends SpeakingEvent {
  const RestartLevel();
}

class SpeakingHintUsed extends SpeakingEvent {
  const SpeakingHintUsed();
}

class RetryCurrentQuestion extends SpeakingEvent {
  const RetryCurrentQuestion();
}

class RestoreLife extends SpeakingEvent {
  const RestoreLife();
}

class AddHint extends SpeakingEvent {
  final int count;
  const AddHint(this.count);

  @override
  List<Object?> get props => [count];
}

class SpeakingTutorPass extends SpeakingEvent {
  const SpeakingTutorPass();
}

// --- STATES ---
abstract class SpeakingState extends Equatable {
  const SpeakingState();

  @override
  List<Object?> get props => [];
}

class SpeakingInitial extends SpeakingState {
  const SpeakingInitial();
}

class SpeakingLoading extends SpeakingState {
  const SpeakingLoading();
}

class SpeakingLoaded extends SpeakingState {
  final List<SpeakingQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  SpeakingQuest get currentQuest => quests[currentIndex];

  const SpeakingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [
        quests,
        currentIndex,
        livesRemaining,
        lastAnswerCorrect,
        hintUsed,
        wrongCount,
        isFinalFailure,
      ];

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

  const SpeakingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class SpeakingGameComplete extends SpeakingState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;

  const SpeakingGameComplete({
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

  const SpeakingGameOver({required this.quests, required this.currentIndex});

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
  }) : super(const SpeakingInitial()) {
    on<FetchSpeakingQuests>((event, emit) async {
      if (state is SpeakingLoading) return;

      final GameSubtype subtype = event.gameType is GameSubtype
          ? event.gameType as GameSubtype
          : GameSubtype.values.firstWhere(
              (s) => s.name == event.gameType.toString(),
              orElse: () => GameSubtype.repeatSentence,
            );
      currentGameType = subtype.name;
      currentLevel = event.level;

      emit(const SpeakingLoading());

      final result = await getQuest(
        QuestParams(gameType: subtype, level: event.level),
      );

      if (isClosed) return;

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
      emit(const SpeakingInitial());
    });

    on<RetryCurrentQuestion>((event, emit) {
      final currentState = state;
      if (currentState is SpeakingLoaded) {
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<SpeakingHintUsed>(_onUseHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
    on<SpeakingTutorPass>(_onTutorPass);

    on<SubmitAnswer>((event, emit) {
      final currentState = state;
      if (currentState is! SpeakingLoaded || currentState.livesRemaining <= 0) return;

      // Guard: Ignore if answer has already been submitted (feedback screen is active)
      if (currentState.lastAnswerCorrect != null) return;

      if (!event.isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        final bool isFinal = newWrongCount >= 2;

        final List<SpeakingQuest> updatedQuests = List.from(currentState.quests);
        if (isFinal) {
          updatedQuests.add(currentState.currentQuest); // Mastery Loop
        }

        // Trigger sounds and haptics asynchronously to avoid race conditions and blocking state updates
        unawaited(soundService.playWrong());
        unawaited(hapticService.error());

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
        unawaited(soundService.playCorrect());
        unawaited(hapticService.success());
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

      // Guard: Ensure an answer has actually been submitted before proceeding to next question
      if (currentState.lastAnswerCorrect == null) return;

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
        unawaited(soundService.playLevelComplete());
        
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
          try {
            await Future.wait([
              updateUserRewards(
                UpdateUserRewardsParams(
                  gameType: currentGameType!,
                  level: currentLevel!,
                  xpIncrease: totalXp,
                  coinIncrease: totalCoins,
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
          } catch (e, stack) {
            debugPrint('Error saving progress in background: $e');
            debugPrint(stack.toString());
          }
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
      if (isClosed) return;

      if (state is SpeakingLoaded) {
        final latestState = state as SpeakingLoaded;
        if (result.isRight()) {
          emit(latestState.copyWith(hintUsed: true));
          unawaited(hapticService.selection());
        }
      }
    }
  }

  void _onRestoreLife(RestoreLife event, Emitter<SpeakingState> emit) {
    final currentState = state;
    if (currentState is SpeakingGameOver) {
      emit(
        SpeakingLoaded(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
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

  void _onTutorPass(SpeakingTutorPass event, Emitter<SpeakingState> emit) {
    final currentState = state;
    if (currentState is SpeakingLoaded) {
      int newLives = currentState.livesRemaining + 1;
      if (newLives > 3) newLives = 3;

      final updatedQuests = List<SpeakingQuest>.from(currentState.quests);
      if (updatedQuests.length > 3) updatedQuests.removeLast();

      unawaited(soundService.playCorrect());
      unawaited(hapticService.success());

      emit(currentState.copyWith(
        livesRemaining: newLives,
        lastAnswerCorrect: true,
        quests: updatedQuests,
      ));
    } else if (currentState is SpeakingGameOver) {
      // Restore from Game Over
      unawaited(soundService.playCorrect());
      unawaited(hapticService.success());
      
      emit(SpeakingLoaded(
        quests: currentState.quests,
        currentIndex: currentState.currentIndex,
        livesRemaining: 1, // Start with 1 life after rescue
        lastAnswerCorrect: true,
      ));
    }
  }
}
