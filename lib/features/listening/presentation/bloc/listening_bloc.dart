import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listening_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';

// --- EVENTS ---
abstract class ListeningEvent {}

class FetchListeningQuests extends ListeningEvent {
  final dynamic gameType;
  final int level;
  FetchListeningQuests({required this.gameType, required this.level});
}

class SubmitAnswer extends ListeningEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);
}

class NextQuestion extends ListeningEvent {}

class RestartLevel extends ListeningEvent {}

class ListeningHintUsed extends ListeningEvent {}

class RestoreLife extends ListeningEvent {}

// --- STATES ---
abstract class ListeningState {}

class ListeningInitial extends ListeningState {}

class ListeningLoading extends ListeningState {}

class ListeningLoaded extends ListeningState {
  final List<ListeningQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;

  ListeningQuest get currentQuest => quests[currentIndex];

  ListeningLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
  });

  ListeningLoaded copyWith({
    List<ListeningQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
  }) {
    return ListeningLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect, // Nullable override
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class ListeningError extends ListeningState {
  final String message;
  ListeningError(this.message);
}

class ListeningGameComplete extends ListeningState {
  final int xpEarned;
  final int coinsEarned;
  ListeningGameComplete({required this.xpEarned, required this.coinsEarned});
}

class ListeningGameOver extends ListeningState {
  final List<ListeningQuest> quests;
  final int currentIndex;
  ListeningGameOver({required this.quests, required this.currentIndex});
}

// --- BLOC ---
class ListeningBloc extends Bloc<ListeningEvent, ListeningState> {
  final dynamic getQuest;
  final dynamic updateUserCoins;
  final dynamic updateUserRewards;
  final dynamic updateCategoryStats;
  final dynamic updateUnlockedLevel;
  final dynamic awardBadge;
  final dynamic soundService;
  final dynamic hapticService;
  final dynamic useHint;
  final NetworkInfo networkInfo;

  String? currentGameType;
  int? currentLevel;

  ListeningBloc({
    this.getQuest,
    this.updateUserCoins,
    this.updateUserRewards,
    this.updateCategoryStats,
    this.updateUnlockedLevel,
    this.awardBadge,
    this.soundService,
    this.hapticService,
    this.useHint,
    required this.networkInfo,
  }) : super(ListeningInitial()) {
    on<FetchListeningQuests>((event, emit) async {
      currentGameType = event.gameType is GameSubtype
          ? (event.gameType as GameSubtype).name
          : event.gameType.toString();
      currentLevel = event.level;

      emit(ListeningLoading());
      try {
        if (getQuest == null) {
          emit(ListeningError("UseCase dependency not provided"));
          return;
        }

        final result = await getQuest!(event.gameType, event.level);

        result.fold((failure) => emit(ListeningError(failure.message)), (
          quests,
        ) {
          if (quests.isEmpty) {
            emit(ListeningError("Check back later for new quests!"));
          } else {
            // ENSURE STICKY 3 QUESTIONS PER LEVEL
            final limitedQuests =
                quests.take(3).toList() as List<ListeningQuest>;
            emit(
              ListeningLoaded(
                quests: limitedQuests,
                currentIndex: 0,
                livesRemaining: 3, // Standard 3 lives
              ),
            );
          }
        });
      } catch (e) {
        emit(ListeningError("Failed to fetch quests: $e"));
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! ListeningLoaded) return;

      int newLives = currentState.livesRemaining;
      if (!event.isCorrect) {
        newLives--;
        if (soundService != null) await soundService.playWrong();
        if (hapticService != null) await hapticService.error();
      } else {
        if (soundService != null) await soundService.playCorrect();
        if (hapticService != null) await hapticService.success();
      }

      emit(
        currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: event.isCorrect,
        ),
      );

      if (newLives <= 0) {
        emit(
          ListeningGameOver(
            quests: currentState.quests,
            currentIndex: currentState.currentIndex,
          ),
        );
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! ListeningLoaded) return;

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
          if (soundService != null) await soundService.playLevelComplete();
          // Calculate rewards
          int totalXp = currentState.quests.fold(
            0,
            (sum, q) => sum + q.xpReward,
          );
          int totalCoins = currentState.quests.fold(
            0,
            (sum, q) => sum + q.coinReward,
          );

          emit(
            ListeningGameComplete(xpEarned: totalXp, coinsEarned: totalCoins),
          );

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
            if (awardBadge != null) await awardBadge!('listening_master');
          }
        }
      } else {
        // Just clear the overlay if it was wrong but they still have lives
        emit(currentState.copyWith(lastAnswerCorrect: null));
      }
    });

    on<ListeningHintUsed>((event, emit) async {
      if (state is ListeningLoaded) {
        final s = state as ListeningLoaded;
        if (s.hintUsed) return;

        if (useHint != null) {
          final success = await useHint!();
          if (success) {
            emit(s.copyWith(hintUsed: true));
            if (hapticService != null) hapticService.selection();
          }
        }
      }
    });

    on<RestoreLife>((event, emit) {
      if (state is ListeningGameOver) {
        final s = state as ListeningGameOver;
        emit(
          ListeningLoaded(
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
      emit(ListeningInitial());
    });
  }
}
