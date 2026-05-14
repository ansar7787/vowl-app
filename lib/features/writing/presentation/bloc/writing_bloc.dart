import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/domain/usecases/use_writing_hint.dart';
import '../../domain/entities/writing_quest.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/writing/domain/usecases/get_writing_quest.dart';
import '../../../../features/speaking/domain/usecases/get_speaking_quest.dart';

// --- EVENTS ---
abstract class WritingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchWritingQuests extends WritingEvent {
  final dynamic gameType;
  final int level;
  FetchWritingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends WritingEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends WritingEvent {}

class RestartLevel extends WritingEvent {}

class WritingHintUsed extends WritingEvent {}

class RetryCurrentQuestion extends WritingEvent {}

class RestoreLife extends WritingEvent {}

// --- STATES ---
abstract class WritingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WritingInitial extends WritingState {}

class WritingLoading extends WritingState {}

class WritingLoaded extends WritingState {
  final List<WritingQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  WritingQuest get currentQuest => quests[currentIndex];

  WritingLoaded({
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

  WritingLoaded copyWith({
    List<WritingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return WritingLoaded(
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

class WritingError extends WritingState {
  final String message;
  final String? technicalError;
  WritingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class WritingGameComplete extends WritingState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  WritingGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class WritingGameOver extends WritingState {
  final List<WritingQuest> quests;
  final int currentIndex;

  WritingGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// --- BLOC ---
class WritingBloc extends Bloc<WritingEvent, WritingState> {
  final GetWritingQuest getQuest;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseWritingHint useHint;

  GameSubtype? currentGameType;
  int? currentLevel;

  WritingBloc({
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.getQuest,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
  }) : super(WritingInitial()) {
    on<FetchWritingQuests>(_onFetchQuests);

    on<RetryCurrentQuestion>((event, emit) {
      if (state is WritingLoaded) {
        final s = state as WritingLoaded;
        emit(s.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! WritingLoaded || currentState.livesRemaining <= 0) return;

      if (!event.isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<WritingQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<WritingQuest>.from(currentState.quests);
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
      if (currentState is! WritingLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(WritingGameOver(
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
        emit(WritingGameComplete(
          xpEarned: totalXp,
          coinsEarned: totalCoins,
          questCount: currentState.quests.length,
        ));

        // 2. Background Save
        if (currentGameType != null && currentLevel != null) {
          await Future.wait([
            updateUserRewards(
              UpdateUserRewardsParams(
                gameType: currentGameType!.name,
                level: currentLevel!,
                xpIncrease: 10,
                coinIncrease: 10,
              ),
            ),
            updateCategoryStats(
              UpdateCategoryStatsParams(
                categoryId: currentGameType!.name,
                isCorrect: true,
              ),
            ),
            updateUnlockedLevel(
              UpdateUnlockedLevelParams(
                categoryId: currentGameType!.name,
                newLevel: currentLevel! + 1,
              ),
            ),
            awardBadge('writing_master'),
          ]);
        }
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<WritingHintUsed>((event, emit) async {
      if (state is WritingLoaded) {
        final s = state as WritingLoaded;
        if (s.hintUsed) return;

        final success = await useHint();
        if (success) {
          emit(s.copyWith(hintUsed: true));
          hapticService.selection();
        }
      }
    });

    on<RestoreLife>((event, emit) {
      if (state is WritingGameOver) {
        final s = state as WritingGameOver;
        emit(
          WritingLoaded(
            quests: s.quests,
            currentIndex: s.currentIndex,
            livesRemaining: 1,
            lastAnswerCorrect: null,
            hintUsed: false,
          ),
        );
      }
    });

    on<RestartLevel>((event, emit) {
      emit(WritingInitial());
    });
  }

  Future<void> _onFetchQuests(
    FetchWritingQuests event,
    Emitter<WritingState> emit,
  ) async {
    final GameSubtype subtype = event.gameType is GameSubtype
        ? event.gameType
        : GameSubtype.values.firstWhere(
            (s) => s.name == event.gameType.toString(),
            orElse: () => GameSubtype.sentenceBuilder,
          );
    currentGameType = subtype;
    currentLevel = event.level;

    emit(WritingLoading());
    try {
      final result = await getQuest(
        QuestParams(gameType: subtype, level: event.level),
      );

      result.fold(
        (failure) => emit(WritingError(
          failure.message,
          technicalError: failure.toString(),
        )),
        (quests) {
          if (quests.isEmpty) {
            emit(WritingError(
              "We couldn't find any quests for this level yet.",
              technicalError: "Empty quest list for ${subtype.name}, Level ${event.level}",
            ));
            return;
          }

          // ENSURE STICKY 3 QUESTIONS PER LEVEL
          final limitedQuests = quests.take(3).toList();
          emit(
            WritingLoaded(
              quests: limitedQuests,
              currentIndex: 0,
              livesRemaining: 3,
            ),
          );
        },
      );
    } catch (e) {
      emit(WritingError("Failed to fetch quests: $e"));
    }
  }
}

