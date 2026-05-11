import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/listening_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_listening_quests.dart';

// --- EVENTS ---
abstract class ListeningEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchListeningQuests extends ListeningEvent {
  final dynamic gameType;
  final int level;
  FetchListeningQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends ListeningEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends ListeningEvent {}

class RestartLevel extends ListeningEvent {}

class ListeningHintUsed extends ListeningEvent {}

class RestoreLife extends ListeningEvent {}

// --- STATES ---
abstract class ListeningState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ListeningInitial extends ListeningState {}

class ListeningLoading extends ListeningState {}

class ListeningLoaded extends ListeningState {
  final List<ListeningQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  ListeningQuest get currentQuest => quests[currentIndex];

  ListeningLoaded({
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

  ListeningLoaded copyWith({
    List<ListeningQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return ListeningLoaded(
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

class ListeningError extends ListeningState {
  final String message;
  final String? technicalError;
  ListeningError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class ListeningGameComplete extends ListeningState {
  final int xpEarned;
  final int coinsEarned;
  ListeningGameComplete({required this.xpEarned, required this.coinsEarned});

  @override
  List<Object?> get props => [xpEarned, coinsEarned];
}

class ListeningGameOver extends ListeningState {
  final List<ListeningQuest> quests;
  final int currentIndex;
  ListeningGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// --- BLOC ---
class ListeningBloc extends Bloc<ListeningEvent, ListeningState> {
  final GetListeningQuests getQuest;
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

  ListeningBloc({
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
  }) : super(ListeningInitial()) {
    on<FetchListeningQuests>((event, emit) async {
      currentGameType = event.gameType is GameSubtype
          ? (event.gameType as GameSubtype).name
          : event.gameType.toString();
      currentLevel = event.level;

      emit(ListeningLoading());
      try {
        final GameSubtype subtype = event.gameType is GameSubtype
            ? event.gameType
            : GameSubtype.values.firstWhere(
                (s) => s.name == event.gameType.toString(),
                orElse: () => GameSubtype.audioMultipleChoice,
              );
        final result = await getQuest(subtype, event.level);

        result.fold((failure) => emit(ListeningError(failure.message)), (
          quests,
        ) {
          if (quests.isEmpty) {
            emit(ListeningError("Check back later for new quests!"));
          } else {
            // ENSURE STICKY 3 QUESTIONS PER LEVEL
            final limitedQuests =
                quests.take(3).toList();
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
      if (currentState is! ListeningLoaded || currentState.livesRemaining <= 0) return;

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

        List<ListeningQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<ListeningQuest>.from(currentState.quests);
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
      if (currentState is! ListeningLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(ListeningGameOver(
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
        // REWARDS: Standardized to match Vocabulary (5 XP, 10 Coins)
        const int totalXp = 10;
        const int totalCoins = 10;

        if (currentGameType != null && currentLevel != null) {
          // 1. Atomic Save: Wait for all background updates to finish
          await Future.wait([
            updateUserRewards(UpdateUserRewardsParams(
              gameType: currentGameType!,
              level: currentLevel!,
              xpIncrease: 10,
              coinIncrease: 10,
            )),
            updateCategoryStats(UpdateCategoryStatsParams(
              categoryId: currentGameType!,
              isCorrect: true,
            )),
            updateUnlockedLevel(UpdateUnlockedLevelParams(
              categoryId: currentGameType!,
              newLevel: currentLevel! + 1,
            )),
            awardBadge('listening_master'),
          ]);
        }

        // 2. Only emit completion after data is safe on the server
        emit(ListeningGameComplete(xpEarned: totalXp, coinsEarned: totalCoins));
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<ListeningHintUsed>((event, emit) async {
      if (state is ListeningLoaded) {
        final s = state as ListeningLoaded;
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
