import 'package:vowl/core/error/failures.dart';
import 'package:dartz/dartz.dart';
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
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';
import 'package:vowl/core/usecases/usecase.dart';

/// Base event for all [KidsBloc] state transitions.
abstract class KidsEvent extends Equatable {
  /// Creates a [KidsEvent].
  const KidsEvent();
  @override
  List<Object?> get props => [];
}

/// Event dispatched to load quests for [gameType] at [level].
class FetchKidsQuests extends KidsEvent {
  /// The game type identifier.
  final String gameType;

  /// The curriculum level number.
  final int level;

  /// Creates a [FetchKidsQuests] event.
  const FetchKidsQuests(this.gameType, this.level);
  @override
  List<Object?> get props => [gameType, level];
}

/// Event dispatched when a child submits an answer.
class SubmitKidsAnswer extends KidsEvent {
  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// Creates a [SubmitKidsAnswer] event.
  const SubmitKidsAnswer(this.isCorrect);
  @override
  List<Object?> get props => [isCorrect];
}

/// Event dispatched to trigger a gameplay hint.
class UseKidsHint extends KidsEvent {
  /// Whether the hint is provided for free without currency deduction.
  final bool isFree;

  /// Creates a [UseKidsHint] event.
  const UseKidsHint({this.isFree = false});
  @override
  List<Object?> get props => [isFree];
}

/// Event dispatched to advance to the next quest question.
class NextKidsQuestion extends KidsEvent {}

/// Event dispatched to claim doubled end-of-level rewards.
class ClaimDoubleKidsRewards extends KidsEvent {
  /// The game type identifier.
  final String gameType;

  /// The level number completed.
  final int level;

  /// Creates a [ClaimDoubleKidsRewards] event.
  const ClaimDoubleKidsRewards(this.gameType, this.level);
  @override
  List<Object?> get props => [gameType, level];
}

/// Event dispatched to restore lost hearts or lives via ad or reward.
class RestoreKidsLife extends KidsEvent {}

/// Event dispatched to restart the current game session.
class ResetKidsGame extends KidsEvent {}

/// Event dispatched to clear immediate answer feedback dialogs or overlays.
class ClearKidsFeedback extends KidsEvent {}

/// Represents the status of the current question's answer submission.
enum AnswerStatus {
  /// The question has not yet been answered.
  unanswered,

  /// The submitted answer was correct.
  correct,

  /// The submitted answer was incorrect.
  incorrect;

  /// Whether the question has been answered.
  bool get isAnswered => this != AnswerStatus.unanswered;

  /// Converts this status to a boolean or null.
  bool? get asBoolOrNull {
    switch (this) {
      case AnswerStatus.unanswered:
        return null;
      case AnswerStatus.correct:
        return true;
      case AnswerStatus.incorrect:
        return false;
    }
  }
}

/// Base state for [KidsBloc].
abstract class KidsState extends Equatable {
  /// Creates a [KidsState].
  const KidsState();
  @override
  List<Object?> get props => [];
}

/// Initial state of the Kids Zone gameplay bloc.
class KidsInitial extends KidsState {
  /// Creates a [KidsInitial] state.
  const KidsInitial();
}

/// State indicating quests are currently being loaded.
class KidsLoading extends KidsState {
  /// Creates a [KidsLoading] state.
  const KidsLoading();
}

/// State representing an active gameplay session with loaded quests.
class KidsLoaded extends KidsState {
  /// The full list of quests in the session.
  final List<KidsQuest> quests;

  /// The total number of quests initially assigned to this session.
  final int originalTotalQuests;

  /// The zero-based index of the currently displayed quest.
  final int currentIndex;

  /// The count of remaining lives or hearts.
  final int livesRemaining;

  /// The answer status of the current question.
  final AnswerStatus answerStatus;

  /// The game type identifier.
  final String gameType;

  /// The curriculum level number.
  final int level;

  /// Whether a hint was used for the current question.
  final bool hintUsed;

  /// Total count of incorrect submissions in this session.
  final int wrongCount;

  /// Whether the player has exhausted all attempts.
  final bool isFinalFailure;

  /// Creates a [KidsLoaded] state.
  const KidsLoaded({
    required this.quests,
    required this.originalTotalQuests,
    required this.gameType,
    required this.level,
    this.currentIndex = 0,
    this.livesRemaining = 3,
    this.answerStatus = AnswerStatus.unanswered,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  /// The currently active [KidsQuest] under inspection.
  KidsQuest get currentQuest => quests[currentIndex];

  /// Creates a copy of this [KidsLoaded] state with replaced values.
  KidsLoaded copyWith({
    List<KidsQuest>? quests,
    int? originalTotalQuests,
    int? currentIndex,
    int? livesRemaining,
    AnswerStatus? answerStatus,
    String? gameType,
    int? level,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return KidsLoaded(
      quests: quests ?? this.quests,
      originalTotalQuests: originalTotalQuests ?? this.originalTotalQuests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      answerStatus: answerStatus ?? this.answerStatus,
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
    answerStatus,
    gameType,
    level,
    hintUsed,
    wrongCount,
    isFinalFailure,
  ];
}

/// State indicating the successful completion of all level quests.
class KidsGameComplete extends KidsState {
  /// The amount of XP awarded for level victory.
  final int xpEarned;

  /// The coin rewards credited.
  final int coinsEarned;

  /// Optional sticker identifier unlocked as reward.
  final String? stickerAwarded;

  /// Creates a [KidsGameComplete] state.
  const KidsGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    this.stickerAwarded,
  });
  @override
  List<Object?> get props => [xpEarned, coinsEarned, stickerAwarded];
}

/// State indicating the player lost all lives before finishing.
class KidsGameOver extends KidsState {
  /// Preserved quest list for continuation.
  final List<KidsQuest> quests;

  /// Original total quest count.
  final int originalTotalQuests;

  /// Current progress index where defeat occurred.
  final int currentIndex;

  /// Game type identifier.
  final String gameType;

  /// Curriculum level number.
  final int level;

  /// Creates a [KidsGameOver] state.
  const KidsGameOver({
    required this.quests,
    required this.originalTotalQuests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [
    quests,
    originalTotalQuests,
    currentIndex,
    gameType,
    level,
  ];
}

/// State representing an error encountered during quest operations.
class KidsError extends KidsState {
  /// Description message of the failure.
  final String message;

  /// Creates a [KidsError] state.
  const KidsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// State representing an error when attempting to use a hint.
class KidsHintError extends KidsState {
  /// Description message of the hint error.
  final String message;

  /// Creates a [KidsHintError] state.
  const KidsHintError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Bloc managing gameplay progression, scoring, hints, and rewards for Kids Zone.
class KidsBloc extends Bloc<KidsEvent, KidsState> {
  /// Use case for quest fetching.
  final GetKidsQuests getKidsQuests;

  /// Use case for updating rewards.
  final UpdateUserRewards updateUserRewards;

  /// Use case for marking levels unlocked.
  final UpdateUnlockedLevel updateUnlockedLevel;

  /// Use case for awarding collectible stickers.
  final AwardKidsSticker awardKidsSticker;

  /// Use case for spending hint tokens.
  final UseHint useHint;

  /// Audio sound effects service.
  final SoundService soundService;

  /// Physical haptic feedback service.
  final HapticService hapticService;

  /// Creates a [KidsBloc] with the required dependencies.
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
          // Re-shuffle options for the context.tr('games.try_again', fallback: 'Try Again') moment
          final reshuffledOptions = List<String>.from(currentQuest.options!)
            ..shuffle();
          final updatedQuests = List<KidsQuest>.from(s.quests);
          updatedQuests[s.currentIndex] = currentQuest.copyWith(
            options: reshuffledOptions,
          );

          emit(
            s.copyWith(
              quests: updatedQuests,
              answerStatus: AnswerStatus.unanswered,
            ),
          );
        } else {
          emit(s.copyWith(answerStatus: AnswerStatus.unanswered));
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
    if (s.answerStatus != AnswerStatus.unanswered || s.livesRemaining <= 0) {
      return;
    }

    // Synchronously lock state transition to prevent double-tap race conditions
    final lockedState = s.copyWith(
      answerStatus: event.isCorrect
          ? AnswerStatus.correct
          : AnswerStatus.incorrect,
    );
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

    // Production Guard: Only re-queue if child has lives remaining,
    // is not already at the last question, and hasn't already queued it.
    final isNotLastQuestion = s.currentIndex < s.quests.length - 1;
    final notAlreadyAppended = !s.quests
        .sublist(s.currentIndex + 1)
        .any((q) => q.id == s.quests[s.currentIndex].id);
    final shouldAppend =
        !event.isCorrect &&
        isFinal &&
        newLives > 0 &&
        isNotLastQuestion &&
        notAlreadyAppended;

    if (shouldAppend) {
      // RE-QUEUE: Move failed quest to the end of the list for reinforcement
      final updatedQuests = List<KidsQuest>.from(s.quests);
      final failedQuest = updatedQuests[s.currentIndex];
      updatedQuests.add(failedQuest);

      emit(
        s.copyWith(
          quests: updatedQuests,
          livesRemaining: newLives,
          answerStatus: AnswerStatus.incorrect,
          wrongCount: 0, // Reset wrongCount after re-queue
          isFinalFailure: true,
        ),
      );
    } else {
      emit(
        s.copyWith(
          livesRemaining: newLives,
          answerStatus: event.isCorrect
              ? AnswerStatus.correct
              : AnswerStatus.incorrect,
          wrongCount: event.isCorrect ? 0 : s.wrongCount + 1,
          isFinalFailure: !event.isCorrect && (s.wrongCount + 1 >= 2),
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextKidsQuestion event,
    Emitter<KidsState> emit,
  ) async {
    if (state is KidsLoaded) {
      final s = state as KidsLoaded;
      if (s.livesRemaining <= 0) {
        emit(
          KidsGameOver(
            quests: s.quests,
            originalTotalQuests: s.originalTotalQuests,
            currentIndex: s.currentIndex,
            gameType: s.gameType,
            level: s.level,
          ),
        );
        return;
      }

      int nextIndex = s.currentIndex + 1;

      if (nextIndex >= s.quests.length) {
        if (s.answerStatus == AnswerStatus.correct) {
          // Level Complete
          String? newSticker;
          if (s.level == 10) {
            newSticker = "sticker_${s.gameType}";
          } else if (s.level == 50 || s.level == 100 || s.level == 200) {
            newSticker = "${s.gameType}_sticker_${s.level}";
          }

          // 0. Synchronously update the reactive stars notifier BEFORE emitting
          // completion so the dialog UI renders the stars instantly without waiting
          // for the Firestore background transaction to complete.
          GamificationRepositoryImpl.lastEarnedStars.value =
              s.livesRemaining > 0 ? s.livesRemaining : 1;

          // 1. Instant UI feedback — emitted immediately to prevent double-taps on the
          // "Continue" button and eliminate UI delays.
          emit(
            KidsGameComplete(
              xpEarned: 5,
              coinsEarned: 10,
              stickerAwarded: newSticker,
            ),
          );

          // 2. Background persistence — Fire-and-forget.
          updateUserRewards(
                UpdateUserRewardsParams(
                  gameType: s.gameType,
                  level: s.level,
                  xpIncrease: 5,
                  coinIncrease: 10,
                  starsEarned: s.livesRemaining > 0 ? s.livesRemaining : 1,
                ),
              )
              .then((_) {
                if (newSticker != null) {
                  awardKidsSticker(
                    newSticker,
                  ).catchError((_) => const Right<Failure, void>(null));
                }
              })
              .catchError((_) {});
        } else {
          // Wrong answer on the very last quest
          emit(
            s.copyWith(
              answerStatus: AnswerStatus.unanswered,
              hintUsed: false,
              wrongCount: 0,
            ),
          );
        }
      } else if (s.answerStatus == AnswerStatus.correct || s.isFinalFailure) {
        emit(
          s.copyWith(
            currentIndex: nextIndex,
            answerStatus: AnswerStatus.unanswered,
            hintUsed: false,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      } else {
        // First-time wrong answer, stay and retry
        emit(
          s.copyWith(answerStatus: AnswerStatus.unanswered, hintUsed: false),
        );
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
      // Production Defense: Prune duplicate copies of the revived question
      // that may have been appended after currentIndex, preventing duplicate replays.
      final sanitizedQuests = List<KidsQuest>.from(s.quests);
      if (s.currentIndex < sanitizedQuests.length) {
        final currentQuestId = sanitizedQuests[s.currentIndex].id;
        for (int i = sanitizedQuests.length - 1; i > s.currentIndex; i--) {
          if (sanitizedQuests[i].id == currentQuestId) {
            sanitizedQuests.removeAt(i);
          }
        }
      }
      // Resume game from where they died with 1 heart
      emit(
        KidsLoaded(
          quests: sanitizedQuests,
          originalTotalQuests: s.originalTotalQuests,
          currentIndex: s.currentIndex,
          gameType: s.gameType,
          level: s.level,
          livesRemaining: 1,
          answerStatus: AnswerStatus.unanswered,
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

      // Optimistic latch: immediately lock hintUsed so concurrent events are rejected
      emit(s.copyWith(hintUsed: true));

      if (event.isFree) {
        return;
      }

      await useHint(NoParams());
    }
  }
}
