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

class UseKidsHint extends KidsEvent {}

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

class KidsInitial extends KidsState {}

class KidsLoading extends KidsState {}

class KidsLoaded extends KidsState {
  final List<KidsQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final String gameType;
  final int level;
  final bool hintUsed;
  final int attempts;
  final bool isFinalFailure;

  const KidsLoaded({
    required this.quests,
    required this.gameType,
    required this.level,
    this.currentIndex = 0,
    this.livesRemaining = 3,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.attempts = 0,
    this.isFinalFailure = false,
  });

  KidsQuest get currentQuest => quests[currentIndex];

  KidsLoaded copyWith({
    List<KidsQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    String? gameType,
    int? level,
    bool? hintUsed,
    int? attempts,
    bool? isFinalFailure,
  }) {
    return KidsLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      hintUsed: hintUsed ?? this.hintUsed,
      attempts: attempts ?? this.attempts,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    gameType,
    level,
    hintUsed,
    attempts,
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
  final int currentIndex;
  final String gameType;
  final int level;

  const KidsGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
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
  }) : super(KidsInitial()) {
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
          // Re-shuffle options for the "Try Again" moment
          final reshuffledOptions = List<String>.from(currentQuest.options!)..shuffle();
          final updatedQuests = List<KidsQuest>.from(s.quests);
          updatedQuests[s.currentIndex] = currentQuest.copyWith(options: reshuffledOptions);
          
          emit(s.copyWith(
            quests: updatedQuests,
            lastAnswerCorrect: null,
          ));
        } else {
          emit(s.copyWith(lastAnswerCorrect: null));
        }
      }
    });
  }

  Future<void> _onFetchQuests(
    FetchKidsQuests event,
    Emitter<KidsState> emit,
  ) async {
    emit(KidsLoading());
    final result = await getKidsQuests(event.gameType, event.level);
    result.fold(
      (failure) =>
          emit(const KidsError('Failed to load quests from assets')),
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
              gameType: event.gameType,
              level: event.level,
            ),
          );
        }
      },
    );
  }

  void _onSubmitAnswer(SubmitKidsAnswer event, Emitter<KidsState> emit) {
    if (state is KidsLoaded) {
      final s = state as KidsLoaded;

      if (event.isCorrect) {
        soundService.playCorrect();
        hapticService.success();
      } else {
        soundService.playWrong();
        hapticService.error();
      }

      int newLives = event.isCorrect ? s.livesRemaining : s.livesRemaining - 1;

      bool isFinal = s.attempts >= 1;

      if (newLives <= 0) {
        emit(
          KidsGameOver(
            quests: s.quests,
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
              attempts: 0, // Reset attempts after re-queue
              isFinalFailure: true,
            ),
          );
        } else {
          emit(
            s.copyWith(
              livesRemaining: newLives,
              lastAnswerCorrect: event.isCorrect,
              attempts: event.isCorrect ? 0 : s.attempts + 1,
              isFinalFailure: !event.isCorrect && (s.attempts + 1 >= 2), // 2nd strike
            ),
          );
        }
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
          await updateUserRewards(
            UpdateUserRewardsParams(
              gameType: s.gameType,
              level: s.level,
              xpIncrease: 10,
              coinIncrease: 10,
            ),
          );
          await updateUnlockedLevel(
            UpdateUnlockedLevelParams(
              categoryId: s.gameType,
              newLevel: s.level + 1,
            ),
          );

          String? newSticker;
          if (s.level == 10) {
            newSticker = "sticker_${s.gameType}";
            await awardKidsSticker(newSticker);
          } else if (s.level == 50 || s.level == 100 || s.level == 200) {
            newSticker = "${s.gameType}_sticker_${s.level}";
            await awardKidsSticker(newSticker);
          }

          emit(
            KidsGameComplete(
              xpEarned: 10,
              coinsEarned: 10,
              stickerAwarded: newSticker,
            ),
          );
        } else {
          // Wrong answer on the very last quest
          emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false, attempts: 0));
        }
      } else if (s.lastAnswerCorrect == true || s.isFinalFailure) {
        emit(s.copyWith(
          currentIndex: nextIndex, 
          lastAnswerCorrect: null,
          hintUsed: false,
          attempts: 0,
          isFinalFailure: false,
        ));
      } else {
        // First-time wrong answer, stay and retry
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
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
        xpIncrease: 10,
        coinIncrease: 10,
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
    emit(KidsInitial());
  }

  Future<void> _onUseHint(UseKidsHint event, Emitter<KidsState> emit) async {
    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      
      // If hint already used for this question, just emit state again to trigger UI refresh if needed
      if (s.hintUsed) return;

      final result = await useHint(NoParams());
      result.fold(
        (failure) => emit(const KidsHintError("No hints left! Visit the shop to get more.")),
        (_) {
          emit(s.copyWith(hintUsed: true));
        },
      );
    }
  }
}
