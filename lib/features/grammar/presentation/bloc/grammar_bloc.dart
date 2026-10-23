import 'package:vowl/core/error/failures.dart';
import 'package:flutter/foundation.dart';

import 'package:vowl/core/utils/sound_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../domain/usecases/get_grammar_quest.dart';
import '../../domain/usecases/preload_grammar_quest.dart';
import '../../domain/entities/grammar_quest.dart';
import '../../../auth/domain/usecases/update_user_rewards.dart';
import '../../../auth/domain/usecases/update_category_stats.dart';
import '../../../auth/domain/usecases/update_unlocked_level.dart';
import '../../../auth/domain/usecases/award_badge.dart';
import '../../../auth/domain/usecases/use_hint.dart';
import '../../../../core/utils/haptic_service.dart';
import '../constants/grammar_constants.dart';

import 'grammar_event.dart';
import 'grammar_state.dart';

export 'grammar_event.dart';
export 'grammar_state.dart';

/// Business logic component managing gameplay state, lives, reward allocation, and sound effects for grammar exercises.
class GrammarBloc extends Bloc<GrammarEvent, GrammarState> {
  /// Use case for fetching grammar quests.
  final GetGrammarQuest getQuest;

  /// Use case for preloading upcoming grammar batches.
  final PreloadGrammarQuest preloadQuest;

  /// Use case for recording XP, coin, and streak rewards.
  final UpdateUserRewards updateUserRewards;

  /// Use case for updating grammar category performance statistics.
  final UpdateCategoryStats updateCategoryStats;

  /// Use case for unlocking progressive curriculum levels.
  final UpdateUnlockedLevel updateUnlockedLevel;

  /// Use case for awarding grammar mastery badges.
  final AwardBadge awardBadge;

  /// Service managing audio and sound playback.
  final SoundService soundService;

  /// Service managing tactile vibration feedback.
  final HapticService hapticService;

  /// Use case managing hint consumption.
  final UseHint useHint;

  // Session-scoped context for persistence. Set once per game session in
  // [_onFetchGrammarQuests] and must not change mid-game.
  GameSubtype? _currentGameType;
  int? _currentLevel;

  /// Creates a [GrammarBloc] instance with all required domain use cases and services.
  GrammarBloc({
    required this.getQuest,
    required this.preloadQuest,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
  }) : super(const GrammarInitial()) {
    on<FetchGrammarQuests>(_onFetchGrammarQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetryQuestion);
    on<GrammarHintUsed>(_onHintUsed);
    on<RestoreLife>(_onRestoreLife);
    on<RestartLevel>(_onRestartLevel);
    on<PreloadGrammarBatch>(_onPreloadBatch);
  }

  Future<void> _onFetchGrammarQuests(
    FetchGrammarQuests event,
    Emitter<GrammarState> emit,
  ) async {
    _currentGameType = event.gameType;
    _currentLevel = event.level;

    emit(const GrammarLoading());

    final result = await getQuest(
      GetGrammarQuestParams(gameType: event.gameType, level: event.level),
    );

    result.fold(
      (failure) => emit(
        GrammarError(
          failure.message,
          technicalError: 'Usecase Failure: ${failure.toString()}',
        ),
      ),
      (quests) {
        if (quests.isEmpty) {
          emit(
            GrammarError(
              'Check back later for new quests!',
              technicalError:
                  'Empty quest list for ${event.gameType.name}, Level ${event.level}',
            ),
          );
          return;
        }

        // Proactively warm the cache when approaching a batch boundary.
        if (event.level % GrammarConstants.preloadTriggerMod ==
            GrammarConstants.preloadTriggerMod) {
          add(
            PreloadGrammarBatch(gameType: event.gameType, level: event.level),
          );
        }

        emit(
          GrammarLoaded(
            quests: quests.take(GrammarConstants.questsPerLevel).toList(),
            currentIndex: 0,
            livesRemaining: GrammarConstants.livesPerLevel,
          ),
        );
      },
    );
  }

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<GrammarState> emit,
  ) async {
    final currentState = state;
    // Guard: wrong state, out of lives, or already answered (anti-double-tap).
    if (currentState is! GrammarLoaded ||
        currentState.livesRemaining <= 0 ||
        currentState.answerStatus.isAnswered) {
      return;
    }

    if (!event.isCorrect) {
      final newLives = currentState.livesRemaining - 1;
      final newWrongCount = currentState.wrongCount + 1;
      final isFinal =
          newWrongCount >= GrammarConstants.wrongAnswersBeforeMasteryLoop;

      // Production Guard: Only re-queue if player has lives remaining,
      // is not already at the last question, and hasn't already queued it.
      final isNotLastQuestion =
          currentState.currentIndex < currentState.quests.length - 1;
      final notAlreadyAppended = !currentState.quests
          .sublist(currentState.currentIndex + 1)
          .any((q) => q.id == currentState.currentQuest.id);
      final shouldAppend =
          isFinal && newLives > 0 && isNotLastQuestion && notAlreadyAppended;

      final updatedQuests = List<GrammarQuest>.from(currentState.quests);
      if (shouldAppend) {
        // Mastery loop: re-queue the failed question at the end.
        updatedQuests.add(currentState.currentQuest);
      }

      soundService.playWrong();
      hapticService.error();

      emit(
        currentState.copyWith(
          livesRemaining: newLives,
          answerStatus: AnswerStatus.incorrect,
          quests: updatedQuests,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    } else {
      soundService.playCorrect();
      hapticService.success();

      emit(
        currentState.copyWith(
          answerStatus: AnswerStatus.correct,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<GrammarState> emit,
  ) async {
    final currentState = state;
    if (currentState is! GrammarLoaded) return;

    if (currentState.livesRemaining <= 0) {
      emit(
        GrammarGameOver(
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
        ),
      );
      return;
    }

    final isLastQuestion =
        currentState.currentIndex + 1 >= currentState.quests.length;

    if (!isLastQuestion) {
      if (currentState.answerStatus.isCorrect || currentState.isFinalFailure) {
        // Advance on success, or after a mastery-loop re-queue.
        emit(
          currentState.copyWith(
            currentIndex: currentState.currentIndex + 1,
            answerStatus: AnswerStatus.unanswered,
            hintUsed: false,
            wrongCount: 0,
            isFinalFailure: false,
          ),
        );
      } else {
        // First wrong answer — stay on the same question for retry.
        emit(
          currentState.copyWith(
            answerStatus: AnswerStatus.unanswered,
            hintUsed: false,
          ),
        );
      }
    } else if (currentState.answerStatus.isCorrect) {
      // Level complete: the last question was answered correctly.

      emit(
        const GrammarGameComplete(
          xpEarned: GrammarConstants.xpPerLevel,
          coinsEarned: GrammarConstants.coinsPerLevel,
          questCount: GrammarConstants.questsPerLevel,
        ),
      );
      _persistLevelCompletion(currentState.livesRemaining);
    } else {
      // Wrong answer on the very last question — allow retry.
      emit(
        currentState.copyWith(
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
        ),
      );
    }
  }

  /// Persists level completion atomically. Errors are caught and logged rather
  /// than surfaced to the UI since [GrammarGameComplete] is already emitted.
  /// The use-case layer is responsible for retry / offline queuing.
  void _persistLevelCompletion(int starsEarned) {
    if (_currentGameType == null || _currentLevel == null) return;

    updateUserRewards(
          UpdateUserRewardsParams(
            gameType: _currentGameType!.name,
            level: _currentLevel!,
            xpIncrease: GrammarConstants.xpPerLevel,
            coinIncrease: GrammarConstants.coinsPerLevel,
            starsEarned: starsEarned,
          ),
        )
        .catchError((e, st) {
          if (kDebugMode) {
            debugPrint('[GrammarBloc] Persistence error: $e\n$st');
          }
          return const Right<Failure, void>(null);
        })
        .then((_) {
          updateCategoryStats(
                UpdateCategoryStatsParams(
                  categoryId: _currentGameType!.name,
                  isCorrect: true,
                ),
              )
              .catchError((e, st) {
                if (kDebugMode) {
                  debugPrint('[GrammarBloc] Persistence error: $e\n$st');
                }
                return const Right<Failure, void>(null);
              })
              .then((_) {
                awardBadge('grammar_master').catchError((e, st) {
                  if (kDebugMode) {
                    debugPrint('[GrammarBloc] Persistence error: $e\n$st');
                  }
                  return const Right<Failure, void>(null);
                });
              });
        });
  }

  void _onRetryQuestion(
    RetryCurrentQuestion event,
    Emitter<GrammarState> emit,
  ) {
    if (state is! GrammarLoaded) return;
    emit(
      (state as GrammarLoaded).copyWith(
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
      ),
    );
  }

  Future<void> _onHintUsed(
    GrammarHintUsed event,
    Emitter<GrammarState> emit,
  ) async {
    if (state is! GrammarLoaded) return;
    final currentState = state as GrammarLoaded;
    if (currentState.hintUsed) return;
    emit(currentState.copyWith(hintUsed: true));
    hapticService.selection();

    final result = await useHint(NoParams());

    // Re-read state after the async boundary to avoid applying a stale snapshot.
    result.fold((_) {
      if (state is GrammarLoaded) {
        emit((state as GrammarLoaded).copyWith(hintUsed: false));
      }
      hapticService.error();
    }, (_) {});
  }

  void _onRestoreLife(RestoreLife event, Emitter<GrammarState> emit) {
    if (state is! GrammarGameOver) return;
    final s = state as GrammarGameOver;

    // Production Defense: Prune any duplicate copies of the revived question
    // that may have been appended after currentIndex, preventing duplicate replays.
    final sanitizedQuests = List<GrammarQuest>.from(s.quests);
    if (s.currentIndex < sanitizedQuests.length) {
      final currentQuestId = sanitizedQuests[s.currentIndex].id;
      for (int i = sanitizedQuests.length - 1; i > s.currentIndex; i--) {
        if (sanitizedQuests[i].id == currentQuestId) {
          sanitizedQuests.removeAt(i);
        }
      }
    }

    emit(
      GrammarLoaded(
        quests: sanitizedQuests,
        currentIndex: s.currentIndex,
        livesRemaining: 1,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
      ),
    );
  }

  void _onRestartLevel(RestartLevel event, Emitter<GrammarState> emit) {
    emit(const GrammarInitial());
  }

  Future<void> _onPreloadBatch(
    PreloadGrammarBatch event,
    Emitter<GrammarState> emit,
  ) async {
    // Fire-and-forget: errors are silently discarded. A cache miss on the
    // next fetch is handled gracefully by the fetch path.
    await preloadQuest(
      PreloadGrammarQuestParams(gameType: event.gameType, level: event.level),
    );
  }
}
