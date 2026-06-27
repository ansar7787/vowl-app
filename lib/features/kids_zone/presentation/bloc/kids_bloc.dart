import 'package:vowl/core/utils/sound_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/domain/usecases/get_kids_quests.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_sticker.dart';

import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/core/usecases/usecase.dart';


// Events
abstract class KidsEvent extends Equatable {
  const KidsEvent();
  @override
  List<Object?> get props => [];
}

class FetchKidsQuests extends KidsEvent {
  final String gameType;
  final int level;
  const FetchKidsQuests(this.gameType, this.level);
  @override
  List<Object?> get props => [gameType, level];
}

class SubmitKidsAnswer extends KidsEvent {
  final bool isCorrect;
  const SubmitKidsAnswer(this.isCorrect);
  @override
  List<Object?> get props => [isCorrect];
}

class UseKidsHint extends KidsEvent {
  final bool isFree;
  const UseKidsHint({this.isFree = false});
  @override
  List<Object?> get props => [isFree];
}

class NextKidsQuestion extends KidsEvent {}

class ClaimDoubleKidsRewards extends KidsEvent {
  final String gameType;
  final int level;
  const ClaimDoubleKidsRewards(this.gameType, this.level);
  @override
  List<Object?> get props => [gameType, level];
}

class RestoreKidsLife extends KidsEvent {}

class ResetKidsGame extends KidsEvent {}

class ClearKidsFeedback extends KidsEvent {}

// States
abstract class KidsState extends Equatable {
  const KidsState();
  @override
  List<Object?> get props => [];
}

class KidsInitial extends KidsState {
  const KidsInitial();
}

class KidsLoading extends KidsState {
  const KidsLoading();
}

class KidsLoaded extends KidsState {
  final List<KidsQuest> quests;
  final int originalTotalQuests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final String gameType;
  final int level;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  const KidsLoaded({
    required this.quests,
    required this.originalTotalQuests,
    required this.gameType,
    required this.level,
    this.currentIndex = 0,
    this.livesRemaining = 3,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  KidsQuest get currentQuest => quests[currentIndex];

  KidsLoaded copyWith({
    List<KidsQuest>? quests,
    int? originalTotalQuests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    String? gameType,
    int? level,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    bool resetLastAnswer = false,
  }) {
    return KidsLoaded(
      quests: quests ?? this.quests,
      originalTotalQuests: originalTotalQuests ?? this.originalTotalQuests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: resetLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }

  @override
  List<Object?> get props => [
    quests,
    originalTotalQuests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    gameType,
    level,
    hintUsed,
    wrongCount,
    isFinalFailure,
  ];
}

class KidsGameComplete extends KidsState {
  final int xpEarned;
  final int coinsEarned;
  final String? stickerAwarded;
  const KidsGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    this.stickerAwarded,
  });
  @override
  List<Object?> get props => [xpEarned, coinsEarned, stickerAwarded];
}

class KidsGameOver extends KidsState {
  // Progress Memory: Save where the kid died so they can resume with an AD
  final List<KidsQuest> quests;
  final int originalTotalQuests;
  final int currentIndex;
  final String gameType;
  final int level;

  const KidsGameOver({
    required this.quests,
    required this.originalTotalQuests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, originalTotalQuests, currentIndex, gameType, level];
}

class KidsError extends KidsState {
  final String message;
  const KidsError(this.message);
  @override
  List<Object?> get props => [message];
}

class KidsHintError extends KidsState {
  final String message;
  const KidsHintError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class KidsBloc extends Bloc<KidsEvent, KidsState> {
  final GetKidsQuests getKidsQuests;
  final UpdateUserRewards updateUserRewards;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardKidsSticker awardKidsSticker;
  final UseHint useHint;
  final SoundService soundService;
  final HapticService hapticService;

  KidsBloc({
    required this.getKidsQuests,
    required this.updateUserRewards,
    required this.updateUnlockedLevel,
    required this.awardKidsSticker,
    required this.useHint,
    required this.soundService,
    required this.hapticService,
  }) : super(const KidsInitial()) {
    on<FetchKidsQuests>(_onFetchQuests);
    on<SubmitKidsAnswer>(_onSubmitAnswer);
    on<NextKidsQuestion>(_onNextQuestion);
    on<ClaimDoubleKidsRewards>(_onClaimDoubleRewards);
    on<RestoreKidsLife>(_onRestoreLife);
    on<ResetKidsGame>(_onResetGame);
    on<UseKidsHint>(_onUseHint);
    on<ClearKidsFeedback>((event, emit) {
      if (state is KidsLoaded) {
        final s = state as KidsLoaded;
        final currentQuest = s.quests[s.currentIndex];
        
        if (currentQuest.options != null && currentQuest.options!.isNotEmpty) {
          // Re-shuffle options for the context.tr('games.try_again') moment
          final reshuffledOptions = List<String>.from(currentQuest.options!)..shuffle();
          final updatedQuests = List<KidsQuest>.from(s.quests);
          updatedQuests[s.currentIndex] = currentQuest.copyWith(options: reshuffledOptions);
          
          emit(s.copyWith(
            quests: updatedQuests,
            resetLastAnswer: true,
          ));
        } else {
          emit(s.copyWith(resetLastAnswer: true));
        }
      }
    });
  }

  Future<void> _onFetchQuests(
    FetchKidsQuests event,
    Emitter<KidsState> emit,
  ) async {
    emit(const KidsLoading());
    final result = await getKidsQuests(event.gameType, event.level);
    result.fold(
      (failure) => emit(const KidsError('Failed to load quests from assets')),
      (quests) {
        final validQuests = quests.where((q) {
          final isMultiChoice = q.gameType == 'choice_multi';
          if (isMultiChoice) {
            return q.correctAnswer != null &&
                q.options != null &&
                q.options!.isNotEmpty;
          }
          return true;
        }).toList();

        if (validQuests.isEmpty) {
          emit(const KidsError('No valid quests available for this level!'));
        } else {
          // SHUFFLE: Randomize options for each quest so kids don't memorize positions
          final shuffledQuests = validQuests.map((q) {
            if (q.options != null && q.options!.isNotEmpty) {
              final shuffledOptions = List<String>.from(q.options!)..shuffle();
              return q.copyWith(options: shuffledOptions);
            }
            return q;
          }).toList();

          emit(
            KidsLoaded(
              quests: shuffledQuests,
              originalTotalQuests: shuffledQuests.length,
              gameType: event.gameType,
              level: event.level,
            ),
          );
        }
      },
    );
  }

  void _onSubmitAnswer(SubmitKidsAnswer event, Emitter<KidsState> emit) {
    if (state is! KidsLoaded) return;
    final s = state as KidsLoaded;
    if (s.lastAnswerCorrect != null || s.livesRemaining <= 0) return;

    // Synchronously lock state transition to prevent double-tap race conditions
    final lockedState = s.copyWith(lastAnswerCorrect: event.isCorrect);
    emit(lockedState);

    if (event.isCorrect) {
      soundService.playCorrect();
      hapticService.success();
    } else {
      soundService.playWrong();
      hapticService.error();
    }

    int newLives = event.isCorrect ? s.livesRemaining : s.livesRemaining - 1;
    bool isFinal = s.wrongCount >= 1;

    if (newLives <= 0) {
      emit(
        KidsGameOver(
          quests: s.quests,
          originalTotalQuests: s.originalTotalQuests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
        ),
      );
    } else {
      if (!event.isCorrect && isFinal) {
        // RE-QUEUE: Move failed quest to the end of the list for reinforcement
        final updatedQuests = List<KidsQuest>.from(s.quests);
        final failedQuest = updatedQuests[s.currentIndex];
        updatedQuests.add(failedQuest);
        
        emit(
          s.copyWith(
            quests: updatedQuests,
            livesRemaining: newLives,
            lastAnswerCorrect: false,
            wrongCount: 0, // Reset wrongCount after re-queue
            isFinalFailure: true,
          ),
        );
      } else {
        emit(
          s.copyWith(
            livesRemaining: newLives,
            lastAnswerCorrect: event.isCorrect,
            wrongCount: event.isCorrect ? 0 : s.wrongCount + 1,
            isFinalFailure: !event.isCorrect && (s.wrongCount + 1 >= 2), // 2nd strike
          ),
        );
      }
    }
  }

  Future<void> _onNextQuestion(
    NextKidsQuestion event,
    Emitter<KidsState> emit,
  ) async {
    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      int nextIndex = s.currentIndex + 1;

      if (nextIndex >= s.quests.length) {
        if (s.lastAnswerCorrect == true) {
          // Level Complete
          String? newSticker;
          if (s.level == 10) {
            newSticker = "sticker_${s.gameType}";
          } else if (s.level == 50 || s.level == 100 || s.level == 200) {
            newSticker = "${s.gameType}_sticker_${s.level}";
          }

          // Emit immediately so UX is perfectly smooth (no loading spinners)
          emit(
            KidsGameComplete(
              xpEarned: 3,
              coinsEarned: 10,
              stickerAwarded: newSticker,
            ),
          );

          // Fire and forget database writes in the background
          Future.wait([
            updateUserRewards(
              UpdateUserRewardsParams(
                gameType: s.gameType,
                level: s.level,
                xpIncrease: 3,
                coinIncrease: 10,
              ),
            ),
            if (newSticker != null) awardKidsSticker(newSticker),
          ]);
        } else {
          // Wrong answer on the very last quest
          emit(s.copyWith(resetLastAnswer: true, hintUsed: false, wrongCount: 0));
        }
      } else if (s.lastAnswerCorrect == true || s.isFinalFailure) {
        emit(s.copyWith(
          currentIndex: nextIndex, 
          resetLastAnswer: true,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        ));
      } else {
        // First-time wrong answer, stay and retry
        emit(s.copyWith(resetLastAnswer: true, hintUsed: false));
      }
    }
  }

  Future<void> _onClaimDoubleRewards(
    ClaimDoubleKidsRewards event,
    Emitter<KidsState> emit,
  ) async {
    await updateUserRewards(
      UpdateUserRewardsParams(
        gameType: event.gameType,
        level: event.level,
        xpIncrease: 0, // No extra XP for ad
        coinIncrease: 20, // +20 coins to triple the base 10 coins
        isDoubleReward: true,
      ),
    );
  }

  void _onRestoreLife(RestoreKidsLife event, Emitter<KidsState> emit) {
    if (state is KidsGameOver) {
      final s = state as KidsGameOver;
      // Resume game from where they died with 1 heart
      emit(
        KidsLoaded(
          quests: s.quests,
          originalTotalQuests: s.originalTotalQuests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
          livesRemaining: 1,
          lastAnswerCorrect: null,
        ),
      );
    }
  }

  void _onResetGame(ResetKidsGame event, Emitter<KidsState> emit) {
    emit(const KidsInitial());
  }

  Future<void> _onUseHint(UseKidsHint event, Emitter<KidsState> emit) async {
    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      
      // If hint already used for this question, don't consume again
      if (s.hintUsed) return;

      if (event.isFree) {
        emit(s.copyWith(hintUsed: true));
        return;
      }

      final result = await useHint(NoParams());
      if (result.isRight()) {
        emit(s.copyWith(hintUsed: true));
      } else {
        // If hint deduction failed on backend but they had local hints, 
        // we still allow them to use the hint in-game so the session doesn't crash.
        emit(s.copyWith(hintUsed: true));
      }
    }
  }
}
