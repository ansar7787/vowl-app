import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reading_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../domain/usecases/get_reading_quest.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/speaking/domain/usecases/get_speaking_quest.dart';

// --- EVENTS ---
abstract class ReadingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchReadingQuests extends ReadingEvent {
  final dynamic gameType;
  final int level;
  FetchReadingQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends ReadingEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends ReadingEvent {}

class RestartLevel extends ReadingEvent {}

class ReadingHintUsed extends ReadingEvent {}

class RestoreLife extends ReadingEvent {}

// --- STATES ---
abstract class ReadingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReadingInitial extends ReadingState {}

class ReadingLoading extends ReadingState {}

class ReadingLoaded extends ReadingState {
  final List<ReadingQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  ReadingQuest get currentQuest => quests[currentIndex];

  ReadingLoaded({
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

  ReadingLoaded copyWith({
    List<ReadingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return ReadingLoaded(
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

class ReadingError extends ReadingState {
  final String message;
  final String? technicalError;
  ReadingError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class ReadingGameComplete extends ReadingState {
  final int xpEarned;
  final int coinsEarned;
  ReadingGameComplete({required this.xpEarned, required this.coinsEarned});

  @override
  List<Object?> get props => [xpEarned, coinsEarned];
}

class ReadingGameOver extends ReadingState {
  final List<ReadingQuest> quests;
  final int currentIndex;
  ReadingGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// --- BLOC ---
class ReadingBloc extends Bloc<ReadingEvent, ReadingState> {
  final GetReadingQuest getQuest;
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

  ReadingBloc({
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
  }) : super(ReadingInitial()) {
    on<FetchReadingQuests>((event, emit) async {
      currentGameType = event.gameType is GameSubtype ? (event.gameType as GameSubtype).name : event.gameType.toString();
      currentLevel = event.level;
      emit(ReadingLoading());
      try {
        final GameSubtype subtype = event.gameType is GameSubtype ? event.gameType : GameSubtype.values.firstWhere((s) => s.name == event.gameType.toString(), orElse: () => GameSubtype.readAndAnswer);
        final result = await getQuest(QuestParams(gameType: subtype, level: event.level));
        result.fold((failure) => emit(ReadingError(failure.message, technicalError: failure.toString())), (quests) {
          if (quests.isEmpty) {
            emit(ReadingError("No comprehension quests found.", technicalError: "Empty list for $currentGameType, Level $currentLevel"));
          } else {
            final limitedQuests = quests.take(3).toList();
            emit(ReadingLoaded(quests: limitedQuests, currentIndex: 0, livesRemaining: 3));
          }
        });
      } catch (e) {
        emit(ReadingError("Failed to fetch reading quests.", technicalError: e.toString()));
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! ReadingLoaded || currentState.livesRemaining <= 0) return;

      if (event.isCorrect) {
        await soundService.playCorrect();
        await hapticService.success();
        emit(currentState.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ));
      } else {
        await soundService.playWrong();
        await hapticService.error();
        
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<ReadingQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<ReadingQuest>.from(currentState.quests);
          updatedQuests.add(currentState.currentQuest);
        }
        emit(currentState.copyWith(
          quests: updatedQuests,
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ));
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! ReadingLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(ReadingGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
        ));
        return;
      }

      if (currentState.currentIndex + 1 < currentState.quests.length) {
        if (currentState.lastAnswerCorrect == true || currentState.isFinalFailure) {
          emit(currentState.copyWith(
            currentIndex: currentState.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
            wrongCount: 0,
            isFinalFailure: false,
          ));
        } else {
          // First-time wrong answer, stay and retry
          emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
        }
      } else if (currentState.lastAnswerCorrect == true) {
        await soundService.playLevelComplete();
        const int totalXp = 10;
        const int totalCoins = 10;
        if (currentGameType != null && currentLevel != null) {
          // 1. First, save everything to the server and await completion
          await Future.wait([
            updateUserRewards(UpdateUserRewardsParams(
              gameType: currentGameType!,
              level: currentLevel!,
              xpIncrease: totalXp,
              coinIncrease: totalCoins,
            )),
            updateCategoryStats(UpdateCategoryStatsParams(
              categoryId: currentGameType!,
              isCorrect: true,
            )),
            updateUnlockedLevel(UpdateUnlockedLevelParams(
              categoryId: currentGameType!,
              newLevel: currentLevel! + 1,
            )),
            awardBadge('reading_master'),
          ]);
        }

        // 2. Only after all saves are confirmed, emit the completion state
        emit(ReadingGameComplete(xpEarned: totalXp, coinsEarned: totalCoins));
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<ReadingHintUsed>((event, emit) async {
      if (state is ReadingLoaded) {
        final s = state as ReadingLoaded;
        if (s.hintUsed) return;
        final result = await useHint(NoParams());
        result.fold((failure) => null, (_) {
          emit(s.copyWith(hintUsed: true));
          hapticService.selection();
        });
      }
    });

    on<RestoreLife>((event, emit) {
      if (state is ReadingGameOver) {
        final s = state as ReadingGameOver;
        emit(ReadingLoaded(quests: s.quests, currentIndex: s.currentIndex, livesRemaining: 1, lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<RestartLevel>((event, emit) {
      emit(ReadingInitial());
    });
  }
}
