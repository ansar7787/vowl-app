import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/core/utils/haptic_service.dart';
import 'package:voxai_quest/core/utils/sound_service.dart';
import 'package:voxai_quest/features/writing/domain/usecases/use_writing_hint.dart';
import '../../domain/entities/writing_quest.dart';

// --- EVENTS ---
abstract class WritingEvent {}

class FetchWritingQuests extends WritingEvent {
  final dynamic gameType;
  final int level;
  FetchWritingQuests({required this.gameType, required this.level});
}

class SubmitAnswer extends WritingEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);
}

class NextQuestion extends WritingEvent {}

class RestartLevel extends WritingEvent {}

class WritingHintUsed extends WritingEvent {}

class RestoreLife extends WritingEvent {}

// --- STATES ---
abstract class WritingState {}

class WritingInitial extends WritingState {}

class WritingLoading extends WritingState {}

class WritingLoaded extends WritingState {
  final List<WritingQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;

  WritingQuest get currentQuest => quests[currentIndex];

  WritingLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
  });

  WritingLoaded copyWith({
    List<WritingQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
  }) {
    return WritingLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect, // Nullable override
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class WritingError extends WritingState {
  final String message;
  WritingError(this.message);
}

class WritingGameComplete extends WritingState {
  final int xpEarned;
  final int coinsEarned;
  WritingGameComplete({required this.xpEarned, required this.coinsEarned});
}

class WritingGameOver extends WritingState {
  final List<WritingQuest> quests;
  final int currentIndex;

  WritingGameOver({required this.quests, required this.currentIndex});
}

// --- BLOC ---
class WritingBloc extends Bloc<WritingEvent, WritingState> {
  final dynamic getQuest;
  final dynamic updateUserCoins;
  final dynamic updateUserRewards;
  final dynamic updateCategoryStats;
  final dynamic updateUnlockedLevel;
  final dynamic awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseWritingHint useHint;

  String? currentGameType;
  int? currentLevel;

  WritingBloc({
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    this.getQuest,
    this.updateUserCoins,
    this.updateUserRewards,
    this.updateCategoryStats,
    this.updateUnlockedLevel,
    this.awardBadge,
  }) : super(WritingInitial()) {
    on<FetchWritingQuests>(_onFetchQuests);

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! WritingLoaded) return;

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
          WritingGameOver(
            quests: currentState.quests,
            currentIndex: currentState.currentIndex,
          ),
        );
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! WritingLoaded) return;

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
          // Calculate rewards
          int totalXp = currentState.quests.fold(
            0,
            (sum, q) => sum + q.xpReward,
          );
          int totalCoins = currentState.quests.fold(
            0,
            (sum, q) => sum + q.coinReward,
          );

          emit(WritingGameComplete(xpEarned: totalXp, coinsEarned: totalCoins));

          // PERSISTENCE
          if (currentGameType != null) {
            if (updateUserCoins != null) await updateUserCoins!(totalXp);
            if (updateUserRewards != null) await updateUserRewards!(totalCoins);
            if (updateCategoryStats != null) {
              await updateCategoryStats!(currentGameType!, 100);
            }
            if (updateUnlockedLevel != null && currentLevel != null) {
              await updateUnlockedLevel!(currentGameType!, currentLevel! + 1);
            }
            if (awardBadge != null) await awardBadge!('writing_master');
          }
        }
      } else {
        // Just clear the overlay if it was wrong but they still have lives
        emit(currentState.copyWith(lastAnswerCorrect: null));
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
    currentGameType = event.gameType is GameSubtype
        ? (event.gameType as GameSubtype).name
        : event.gameType.toString();
    currentLevel = event.level;

    emit(WritingLoading());
    try {
      if (getQuest == null) {
        emit(WritingError("UseCase dependency not provided"));
        return;
      }

      final List<WritingQuest> quests = [];
      try {
        final result = await getQuest!(event.gameType, event.level);
        if (result != null && result is List<WritingQuest>) {
          quests.addAll(result);
        }
      } catch (e) {
        try {
          final result = await getQuest!(event.gameType);
          if (result != null && result is List<WritingQuest>) {
            quests.addAll(result);
          }
        } catch (_) {}
      }

      if (quests.isEmpty) {
        emit(WritingError("We couldn't find any quests for this level yet."));
        return;
      }

      if (quests.isEmpty) {
        emit(WritingError("Check back later for new quests!"));
      } else {
        // ENSURE STICKY 3 QUESTIONS PER LEVEL
        final limitedQuests = quests.take(3).toList();
        emit(
          WritingLoaded(
            quests: limitedQuests,
            currentIndex: 0,
            livesRemaining: 3, // Standard 3 lives
          ),
        );
      }
    } catch (e) {
      emit(WritingError("Failed to fetch quests: $e"));
    }
  }
}
