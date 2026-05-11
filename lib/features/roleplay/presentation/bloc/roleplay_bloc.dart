import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/roleplay_quest.dart';
import '../../domain/usecases/get_roleplay_quest.dart';
import '../../domain/usecases/preload_roleplay_quests.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';

// --- EVENTS ---
abstract class RoleplayEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchRoleplayQuests extends RoleplayEvent {
  final GameSubtype gameType;
  final int level;
  FetchRoleplayQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SelectDialogueChoice extends RoleplayEvent {
  final DialogueChoice choice;
  SelectDialogueChoice(this.choice);

  @override
  List<Object?> get props => [choice];
}

class SubmitAnswer extends RoleplayEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends RoleplayEvent {}

class RestartLevel extends RoleplayEvent {}

class RoleplayHintUsed extends RoleplayEvent {}

class RestoreLife extends RoleplayEvent {}

class PreloadNextBatch extends RoleplayEvent {
  final GameSubtype gameType;
  final int currentLevel;
  PreloadNextBatch({required this.gameType, required this.currentLevel});

  @override
  List<Object?> get props => [gameType, currentLevel];
}

// --- STATES ---
abstract class RoleplayState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RoleplayInitial extends RoleplayState {}

class RoleplayLoading extends RoleplayState {}

class RoleplayLoaded extends RoleplayState {
  final List<RoleplayQuest> quests;
  final int currentIndex;
  final String? currentNodeId;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final String? errorMessage;
  final GameSubtype gameType;
  final int level;
  final int wrongCount;
  final bool isFinalFailure;

  RoleplayQuest get currentQuest => quests[currentIndex];
  DialogueNode? get currentNode =>
      currentQuest.dialogues?[currentNodeId ?? 'start'];

  RoleplayLoaded({
    required this.quests,
    required this.currentIndex,
    this.currentNodeId,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.errorMessage,
    required this.gameType,
    required this.level,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [
        quests,
        currentIndex,
        currentNodeId,
        livesRemaining,
        lastAnswerCorrect,
        hintUsed,
        errorMessage,
        gameType,
        level,
        wrongCount,
        isFinalFailure,
      ];

  RoleplayLoaded copyWith({
    List<RoleplayQuest>? quests,
    int? currentIndex,
    String? currentNodeId,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    String? errorMessage,
    GameSubtype? gameType,
    int? level,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return RoleplayLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
      errorMessage: errorMessage,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

class RoleplayError extends RoleplayState {
  final String message;
  final String? technicalError;
  RoleplayError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class RoleplayGameComplete extends RoleplayState {
  final int xpEarned;
  final int coinsEarned;
  final RoleplayLoaded lastState;
  RoleplayGameComplete({required this.xpEarned, required this.coinsEarned, required this.lastState});

  @override
  List<Object?> get props => [xpEarned, coinsEarned, lastState];
}

class RoleplayGameOver extends RoleplayState {
  final List<RoleplayQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;
  RoleplayGameOver({required this.quests, required this.currentIndex, required this.gameType, required this.level});

  @override
  List<Object?> get props => [quests, currentIndex, gameType, level];
}

// --- BLOC ---
class RoleplayBloc extends Bloc<RoleplayEvent, RoleplayState> {
  final GetRoleplayQuest getQuest;
  final PreloadRoleplayQuests preloadQuests;
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

  RoleplayBloc({
    required this.getQuest,
    required this.preloadQuests,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(RoleplayInitial()) {
    on<FetchRoleplayQuests>((event, emit) async {
      currentGameType = event.gameType.name;
      currentLevel = event.level;
      emit(RoleplayLoading());
      
      final result = await getQuest(gameType: event.gameType, level: event.level);
      result.fold(
        (failure) => emit(RoleplayError("Failed to load quests")),
        (loadedQuests) {
          if (loadedQuests.isEmpty) {
            emit(RoleplayError("No quests available for this level"));
          } else {
            emit(RoleplayLoaded(
              quests: loadedQuests,
              currentIndex: 0,
              livesRemaining: loadedQuests.first.livesAllowed,
              gameType: event.gameType,
              level: event.level,
              currentNodeId: 'start',
            ));
          }
        },
      );
    });

    on<SelectDialogueChoice>((event, emit) async {
      final currentState = state;
      if (currentState is! RoleplayLoaded || currentState.livesRemaining <= 0) return;

      final isCorrect = (event.choice.score ?? 100) >= 50;

      if (!isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<RoleplayQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<RoleplayQuest>.from(currentState.quests);
          updatedQuests.add(currentState.currentQuest);
        }

        await soundService.playWrong();
        await hapticService.error();

        emit(currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          quests: updatedQuests,
          currentNodeId: event.choice.next,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ));
      } else {
        await soundService.playCorrect();
        await hapticService.success();
        emit(currentState.copyWith(
          lastAnswerCorrect: true,
          currentNodeId: event.choice.next,
          wrongCount: 0,
          isFinalFailure: false,
        ));
      }
    });

    on<SubmitAnswer>((event, emit) async {
      final currentState = state;
      if (currentState is! RoleplayLoaded || currentState.livesRemaining <= 0) return;

      if (!event.isCorrect) {
        final newLives = currentState.livesRemaining - 1;
        final newWrongCount = currentState.wrongCount + 1;
        bool isFinal = newWrongCount >= 2;

        List<RoleplayQuest> updatedQuests = currentState.quests;
        if (isFinal) {
          updatedQuests = List<RoleplayQuest>.from(currentState.quests);
          updatedQuests.add(currentState.currentQuest);
        }

        await soundService.playWrong();
        await hapticService.error();

        emit(currentState.copyWith(
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          quests: updatedQuests,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal,
        ));
      } else {
        await soundService.playCorrect();
        await hapticService.success();
        emit(currentState.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ));
      }
    });

    on<NextQuestion>((event, emit) async {
      final currentState = state;
      if (currentState is! RoleplayLoaded) return;

      if (currentState.livesRemaining <= 0) {
        emit(RoleplayGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
          gameType: currentState.gameType,
          level: currentState.level,
        ));
        return;
      }

      if (currentState.currentIndex + 1 < currentState.quests.length) {
        if (currentState.lastAnswerCorrect == true || currentState.isFinalFailure) {
          emit(currentState.copyWith(
            currentIndex: currentState.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
            currentNodeId: 'start',
            errorMessage: null,
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

        emit(RoleplayGameComplete(xpEarned: totalXp, coinsEarned: totalCoins, lastState: currentState));

        if (currentGameType != null && currentLevel != null) {
          await updateUserRewards(UpdateUserRewardsParams(gameType: currentGameType!, level: currentLevel!, xpIncrease: totalXp, coinIncrease: totalCoins));
          await updateCategoryStats(UpdateCategoryStatsParams(categoryId: currentGameType!, isCorrect: true));
          await updateUnlockedLevel(UpdateUnlockedLevelParams(categoryId: currentGameType!, newLevel: currentLevel! + 1));
          await awardBadge('roleplay_master');
        }
      } else {
        // Wrong answer on the very last quest
        emit(currentState.copyWith(lastAnswerCorrect: null, hintUsed: false));
      }
    });

    on<RoleplayHintUsed>((event, emit) async {
      if (state is RoleplayLoaded) {
        final s = state as RoleplayLoaded;
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
      if (state is RoleplayGameOver) {
        final s = state as RoleplayGameOver;
        emit(RoleplayLoaded(quests: s.quests, currentIndex: s.currentIndex, livesRemaining: 1, lastAnswerCorrect: null, hintUsed: false, gameType: s.gameType, level: s.level, currentNodeId: 'start'));
      }
    });

    on<RestartLevel>((event, emit) {
      emit(RoleplayInitial());
    });
  }
}
