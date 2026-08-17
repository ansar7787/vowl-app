import 'dart:developer' as dev;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/usecases/usecase.dart';
import '../../domain/entities/elite_mastery_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../domain/usecases/get_elite_mastery_quests.dart';
import '../../../../core/utils/haptic_service.dart';
import '../../../../core/utils/sound_service.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import '../../../../core/utils/hint_utility.dart';
import '../../../../core/presentation/bloc/game_state_base.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';

part 'elite_mastery_event.dart';
part 'elite_mastery_state.dart';

class EliteMasteryBloc extends Bloc<EliteMasteryEvent, EliteMasteryState> {
  final GetEliteMasteryQuests getQuests;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final UseHint useHint;
  final SoundService soundService;
  final HapticService hapticService;

  // ── Game constants ──────────────────────────────────────────────────────────
  static const int _maxLives = 3;
  static const int _questsPerLevel = 3;
  static const int _maxWrongAttempts = 2;
  static const int _xpReward = 10;
  static const int _coinReward = 10;

  // ── Constructor ─────────────────────────────────────────────────────────────

  EliteMasteryBloc({
    required this.getQuests,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.useHint,
    required this.soundService,
    required this.hapticService,
  }) : super(const EliteMasteryInitial()) {
    on<RetryEliteQuestion>(_onRetryEliteQuestion);
    on<FetchEliteMasteryQuests>(_onFetchEliteMasteryQuests);
    on<SubmitEliteAnswer>(_onSubmitEliteAnswer);
    on<NextEliteQuestion>(_onNextEliteQuestion);
    on<ShowEliteHint>(_onShowEliteHint);
    on<MarkEliteHintUsed>(_onMarkEliteHintUsed);
    on<AddLifeFromAd>(_onAddLifeFromAd);
    on<RestoreEliteLife>(_onRestoreEliteLife);
    on<EliteTutorPass>(_onEliteTutorPass);
    on<EliteSpeakConfirmed>(_onSpeakConfirmed);
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  void _onRetryEliteQuestion(
    RetryEliteQuestion event,
    Emitter<EliteMasteryState> emit,
  ) {
    if (state is! EliteMasteryLoaded) return;
    final s = state as EliteMasteryLoaded;
    emit(
      s.copyWith(
        answerStatus: AnswerStatus.unanswered,
        isHintUsed: false,
        removedIndices: const [],
        isLetterRevealed: false,
      ),
    );
  }

  Future<void> _onFetchEliteMasteryQuests(
    FetchEliteMasteryQuests event,
    Emitter<EliteMasteryState> emit,
  ) async {
    emit(const EliteMasteryLoading());

    final result = await getQuests(
      GetEliteMasteryQuestParams(gameType: event.gameType, level: event.level),
    );

    result.fold(
      (failure) {
        // FIX: `failure.message` is plain, hardcoded English produced by the
        // data/repository layer (which — correctly, per Clean Architecture —
        // has no access to `BuildContext`/localization). Tagging it with a
        // `reason` lets the presentation layer (`EliteBaseLayout`) show a
        // fully localized string for the common, known cause instead of
        // always falling back to raw English text. See
        // `EliteMasteryErrorReason` for details.
        final reason = failure is ServerFailure
            ? EliteMasteryErrorReason.loadFailed
            : EliteMasteryErrorReason.unknown;
        emit(EliteMasteryError(failure.message, reason: reason));
      },
      (quests) {
        if (quests.isEmpty) {
          emit(
            const EliteMasteryError(
              'No quests found for this level.',
              reason: EliteMasteryErrorReason.noQuestsForLevel,
            ),
          );
          return;
        }
        emit(
          EliteMasteryLoaded(
            gameType: event.gameType,
            level: event.level,
            quests: quests.take(_questsPerLevel).toList(),
            currentIndex: 0,
            livesRemaining: _maxLives,
          ),
        );
      },
    );
  }

  void _onSubmitEliteAnswer(
    SubmitEliteAnswer event,
    Emitter<EliteMasteryState> emit,
  ) {
    final currentState = state;
    if (currentState is! EliteMasteryLoaded ||
        currentState.livesRemaining <= 0 ||
        currentState.answerStatus == AnswerStatus.correct) {
      return;
    }

    if (!event.isCorrect) {
      final newLives = currentState.livesRemaining - 1;
      final newWrongCount = currentState.wrongCount + 1;
      final isFinal = newWrongCount >= _maxWrongAttempts;

      final updatedQuests = isFinal
          ? (List<EliteMasteryQuest>.from(currentState.quests)
              ..add(currentState.currentQuest))
          : currentState.quests;

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

  Future<void> _onNextEliteQuestion(
    NextEliteQuestion event,
    Emitter<EliteMasteryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EliteMasteryLoaded) return;

    // ── Out of lives ─────────────────────────────────────────────────────────
    if (currentState.livesRemaining <= 0) {
      emit(
        EliteMasteryGameOver(
          gameType: currentState.gameType,
          level: currentState.level,
          quests: currentState.quests,
          currentIndex: currentState.currentIndex,
        ),
      );
      return;
    }

    final hasMoreQuests =
        currentState.currentIndex + 1 < currentState.quests.length;

    if (hasMoreQuests) {
      if (currentState.answerStatus == AnswerStatus.correct ||
          currentState.isFinalFailure) {
        emit(
          currentState.copyWith(
            currentIndex: currentState.currentIndex + 1,
            answerStatus: AnswerStatus.unanswered,
            isHintVisible: false,
            isHintUsed: false,
            wrongCount: 0,
            isFinalFailure: false,
            removedIndices: const [],
            isLetterRevealed: false,
          ),
        );
      } else {
        emit(
          currentState.copyWith(
            answerStatus: AnswerStatus.unanswered,
            isHintVisible: false,
            removedIndices: const [],
            isLetterRevealed: false,
          ),
        );
      }
    } else if (currentState.answerStatus == AnswerStatus.correct) {
      // ── Level complete ────────────────────────────────────────────────────
      soundService.playLevelComplete();

      emit(
        EliteMasteryGameComplete(
          xpEarned: _xpReward,
          coinsEarned: _coinReward,
          questCount: currentState.quests.length,
        ),
      );

      // Resolve nullable fields — both are always set by the BLoC in
      // production, but are nullable for backward compatibility with
      // existing tests and mock states.
      final gameTypeName = currentState.gameType?.name;
      final level = currentState.level;

      if (gameTypeName == null || level == null) {
        dev.log(
          'Reward update skipped: gameType or level not present in state. '
          'This is expected in test environments; unexpected in production.',
          name: 'EliteMasteryBloc',
        );
        return;
      }

      // Each reward-persistence call is wrapped so it can never throw past
      // this point. Previously all three calls were passed straight into a
      // single `Future.wait`, which is eager: the *first* rejected future
      // is what the surrounding try/catch sees, while the other in-flight
      // calls keep running in the background. If one of those later also
      // failed, that became an unhandled async exception outside any
      // catch block — invisible in release builds, but a real crash-report
      // risk. Wrapping each call also means one failing step (e.g. the
      // streak/category stats write) can never prevent the other two
      // (XP/coins, level unlock) from being attempted.
      await Future.wait([
        _persistRewardSafely(
          'updateUserRewards',
          () => updateUserRewards(
            UpdateUserRewardsParams(
              gameType: gameTypeName,
              level: level,
              xpIncrease: _xpReward,
              coinIncrease: _coinReward,
              starsEarned: currentState.livesRemaining,
            ),
          ),
        ),
        _persistRewardSafely(
          'updateCategoryStats',
          () => updateCategoryStats(
            UpdateCategoryStatsParams(
              categoryId: gameTypeName,
              isCorrect: true,
            ),
          ),
        ),
        // FIX (critical): `updateUnlockedLevel` was injected as a constructor
        // dependency but was never actually called anywhere in this class.
        // Level completion was awarding XP/coins/category-stats but never
        // persisting level-progression — i.e. the next level never actually
        // unlocked for the player. NOTE: field names below mirror this
        // file's existing `UpdateUserRewardsParams` convention (gameType +
        // level); please verify them against the real
        // `UpdateUnlockedLevelParams` in
        // features/auth/domain/usecases/update_unlocked_level.dart (outside
        // this feature slice) and adjust if they differ.
        _persistRewardSafely(
          'updateUnlockedLevel',
          () => updateUnlockedLevel(
            UpdateUnlockedLevelParams(
              categoryId: gameTypeName,
              newLevel: level + 1,
            ),
          ),
        ),
      ]);
    } else {
      // Wrong answer on the last quest — stay and retry.
      emit(currentState.copyWith(answerStatus: AnswerStatus.unanswered, isHintVisible: false));
    }
  }

  /// Runs a single reward-persistence call, logging (rather than rethrowing)
  /// any failure so it can never surface as an unhandled async exception and
  /// can never block its sibling calls in [_onNextEliteQuestion]'s
  /// `Future.wait`.
  ///
  /// NOTE: this only guards against *thrown* exceptions. If
  /// [updateUserRewards] / [updateCategoryStats] / [updateUnlockedLevel]
  /// return an `Either<Failure, ...>` rather than throwing on failure, a
  /// `Left` result is still swallowed silently here — exactly as it was
  /// before this fix. Folding those results explicitly would need their
  /// concrete return type, which isn't visible from this file alone.
  Future<void> _persistRewardSafely(
    String label,
    Future<dynamic> Function() action,
  ) async {
    try {
      await action();
    } catch (e, st) {
      dev.log(
        'Failed to persist reward step: $label',
        name: 'EliteMasteryBloc',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onShowEliteHint(ShowEliteHint event, Emitter<EliteMasteryState> emit) {
    if (state is! EliteMasteryLoaded) return;
    hapticService.selection();
    emit((state as EliteMasteryLoaded).copyWith(isHintVisible: true));
  }

  Future<void> _onMarkEliteHintUsed(
    MarkEliteHintUsed event,
    Emitter<EliteMasteryState> emit,
  ) async {
    if (state is! EliteMasteryLoaded) return;
    final currentState = state as EliteMasteryLoaded;
    final result = await useHint(NoParams());
    if (result.isRight()) {
      List<int> removedIndices = [];
      bool isLetterRevealed = false;
      final quest = currentState.currentQuest;

      // If it's a generic hint, trigger dynamic 50/50 lifeline or letter reveal
      if (HintUtility.isGenericHint(quest.hint)) {
        if (quest.options != null && quest.options!.length > 2) {
          final correctIdx = quest.correctAnswerIndex ?? 0;
          final wrongIndices = <int>[];
          for (var i = 0; i < quest.options!.length; i++) {
            if (i != correctIdx) wrongIndices.add(i);
          }
          wrongIndices.shuffle();
          final removeCount = (wrongIndices.length / 2).ceil();
          removedIndices = wrongIndices.take(removeCount).toList();
        } else if (quest.word != null) {
          isLetterRevealed = true;
        }
      }

      emit(
        currentState.copyWith(
          isHintUsed: true,
          removedIndices: removedIndices,
          isLetterRevealed: isLetterRevealed,
        ),
      );
    }
  }

  void _onAddLifeFromAd(AddLifeFromAd event, Emitter<EliteMasteryState> emit) {
    if (state is EliteMasteryGameOver) {
      emit(_restoreFromGameOver(state as EliteMasteryGameOver));
    } else if (state is EliteMasteryLoaded) {
      final s = state as EliteMasteryLoaded;
      // FIX: previously unclamped — repeated ad-grants (or a grant stacked
      // on top of an already-full life bar) could push `livesRemaining`
      // above `_maxLives`, desyncing the heart count from the header's
      // `_kMaxLives`-based UI and from `EliteTutorPass`'s own clamped logic
      // just below.
      emit(
        s.copyWith(livesRemaining: (s.livesRemaining + 1).clamp(0, _maxLives)),
      );
    }
  }

  void _onRestoreEliteLife(
    RestoreEliteLife event,
    Emitter<EliteMasteryState> emit,
  ) {
    if (state is EliteMasteryGameOver) {
      emit(_restoreFromGameOver(state as EliteMasteryGameOver));
    }
  }

  Future<void> _onEliteTutorPass(
    EliteTutorPass event,
    Emitter<EliteMasteryState> emit,
  ) async {
    final currentState = state;

    if (currentState is EliteMasteryLoaded) {
      final newLives = (currentState.livesRemaining + 1).clamp(0, _maxLives);

      soundService.playCorrect();
      hapticService.success();

      emit(
        currentState.copyWith(
          livesRemaining: newLives,
          answerStatus: AnswerStatus.correct,
          quests: _trimRequeuedFailure(currentState.quests),
        ),
      );
    } else if (currentState is EliteMasteryGameOver) {
      soundService.playCorrect();
      hapticService.success();

      emit(
        EliteMasteryLoaded(
          gameType: currentState.gameType,
          level: currentState.level,
          // FIX: a final failure pushes a duplicate of the failed quest to
          // the end of the list (see `_onSubmitEliteAnswer`) so it can be
          // retried later. The Loaded-state branch above already trims that
          // duplicate when Tutor Pass overrides a failure, but this
          // Game-Over branch — reached via the "Restore"/"Tutor Pass" dialog
          // after lives hit zero — previously did not, silently forcing the
          // player to repeat the exact same sentence a second time later in
          // the same session despite having been told it was marked correct.
          quests: _trimRequeuedFailure(currentState.quests),
          currentIndex: currentState.currentIndex,
          livesRemaining: 1,
          answerStatus: AnswerStatus.correct,
        ),
      );
    }
  }

  Future<void> _onSpeakConfirmed(
    EliteSpeakConfirmed event,
    Emitter<EliteMasteryState> emit,
  ) async {
    try {
      await updateUserCoins(
        UpdateUserCoinsParams(
          amountChange: event.bonusCoins,
          title: 'coin_history.speaking_bonus',
          isEarned: true,
        ),
      );
    } catch (e) {
      dev.log('Failed to add speak confirmed coins', error: e);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Builds a recovery [EliteMasteryLoaded] from [EliteMasteryGameOver] with
  /// one life remaining.  Shared by [_onAddLifeFromAd] and [_onRestoreEliteLife]
  /// to keep construction logic in one place.
  EliteMasteryLoaded _restoreFromGameOver(EliteMasteryGameOver s) {
    return EliteMasteryLoaded(
      gameType: s.gameType,
      level: s.level,
      quests: s.quests,
      currentIndex: s.currentIndex,
      livesRemaining: 1,
    );
  }

  /// Removes the trailing requeued-failure duplicate that
  /// [_onSubmitEliteAnswer] appends when a quest is failed for good, if
  /// present. Shared by both branches of [_onEliteTutorPass] so an honesty-
  /// nudge override never leaves the player to repeat the same quest twice.
  List<EliteMasteryQuest> _trimRequeuedFailure(List<EliteMasteryQuest> quests) {
    if (quests.length <= _questsPerLevel) return quests;
    return List<EliteMasteryQuest>.from(quests)..removeLast();
  }
}
