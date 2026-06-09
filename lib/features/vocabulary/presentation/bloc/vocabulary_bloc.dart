import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/domain/usecases/update_user_rewards.dart';
import '../../../../features/auth/domain/usecases/update_category_stats.dart';
import '../../../../features/auth/domain/usecases/update_unlocked_level.dart';
import '../../../../features/auth/domain/usecases/update_user_coins.dart';
import '../../../../features/auth/domain/usecases/award_badge.dart';
import '../../../../features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import '../../domain/entities/vocabulary_quest.dart';
import '../../domain/usecases/get_vocabulary_quests.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/usecases/usecase.dart';

// ─────────────────────────────────────────────
// CATCH-ERROR HELPER
// ─────────────────────────────────────────────

Either<Failure, void> _swallow(Object _) => const Right(null);

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

/// Central reward constants — change once, reflected everywhere.
class VocabularyRewardConstants {
  const VocabularyRewardConstants._();

  static const int baseXp = 10;
  static const int baseCoins = 10;
  static const int initialLives = 3;
  static const int reviveLives = 1;
  static const int maxQuestsPerLevel = 3;
  static const int wrongCountBeforeMasteryLoop = 2;
  static const String masteryBadgeId = 'vocabulary_master';
}

// ─────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────

abstract class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object?> get props => [];
}

class FetchVocabularyQuests extends VocabularyEvent {
  final GameSubtype gameType;
  final int level;

  const FetchVocabularyQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends VocabularyEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends VocabularyEvent {
  const NextQuestion();
}

class RetryCurrentQuestion extends VocabularyEvent {
  const RetryCurrentQuestion();
}

class RestartLevel extends VocabularyEvent {
  const RestartLevel();
}

class VocabularyHintUsed extends VocabularyEvent {
  const VocabularyHintUsed();
}

class RestoreLife extends VocabularyEvent {
  const RestoreLife();
}

/// Was a complete no-op stub — added count to hintsAvailable state.
class AddHint extends VocabularyEvent {
  final int count;

  const AddHint(this.count);

  @override
  List<Object?> get props => [count];
}

// ─────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────

abstract class VocabularyState extends Equatable {
  const VocabularyState();

  @override
  List<Object?> get props => [];
}

class VocabularyInitial extends VocabularyState {
  const VocabularyInitial();
}

class VocabularyLoading extends VocabularyState {
  const VocabularyLoading();
}

class VocabularyLoaded extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  ///  Added hintsAvailable so AddHint event has a state destination.
  final int hintsAvailable;

  const VocabularyLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
    this.hintsAvailable = 0,
  });

  /// Bounds-checked getter — clear assert instead of cryptic RangeError.
  VocabularyQuest get currentQuest {
    assert(
      currentIndex >= 0 && currentIndex < quests.length,
      'currentIndex ($currentIndex) out of bounds (${quests.length})',
    );
    return quests[currentIndex];
  }

  /// Safe nullable getter — use this in UI to avoid crashes.
  VocabularyQuest? get currentQuestOrNull =>
      (currentIndex >= 0 && currentIndex < quests.length)
      ? quests[currentIndex]
      : null;

  @override
  List<Object?> get props => [
    quests,
    currentIndex,
    livesRemaining,
    lastAnswerCorrect,
    hintUsed,
    wrongCount,
    isFinalFailure,
    hintsAvailable,
  ];

  VocabularyLoaded copyWith({
    List<VocabularyQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    int? hintsAvailable,

    ///  Explicit flag to intentionally clear lastAnswerCorrect.
    /// Passing lastAnswerCorrect: null previously reset it unintentionally.
    bool clearLastAnswerCorrect = false,
  }) {
    return VocabularyLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: clearLastAnswerCorrect
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      hintUsed: hintUsed ?? this.hintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
      hintsAvailable: hintsAvailable ?? this.hintsAvailable,
    );
  }
}

class VocabularyError extends VocabularyState {
  final String message;
  final String? technicalError;

  const VocabularyError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class VocabularyGameComplete extends VocabularyState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;

  const VocabularyGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class VocabularyGameOver extends VocabularyState {
  final List<VocabularyQuest> quests;
  final int currentIndex;

  const VocabularyGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}

// ─────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final GetVocabularyQuests getQuests;
  final UpdateUserCoins updateUserCoins;
  final UpdateUserRewards updateUserRewards;
  final UpdateCategoryStats updateCategoryStats;
  final UpdateUnlockedLevel updateUnlockedLevel;
  final AwardBadge awardBadge;
  final SoundService soundService;
  final HapticService hapticService;
  final UseHint useHint;
  final NetworkInfo networkInfo;

  //  Private — internal state, not public API.
  String? _currentGameType;
  int? _currentLevel;

  String? get currentGameType => _currentGameType;
  int? get currentLevel => _currentLevel;

  VocabularyBloc({
    required this.getQuests,
    required this.updateUserCoins,
    required this.updateUserRewards,
    required this.updateCategoryStats,
    required this.updateUnlockedLevel,
    required this.awardBadge,
    required this.soundService,
    required this.hapticService,
    required this.useHint,
    required this.networkInfo,
  }) : super(const VocabularyInitial()) {
    on<FetchVocabularyQuests>(_onFetchQuests);
    on<SubmitAnswer>(_onSubmitAnswer);
    on<NextQuestion>(_onNextQuestion);
    on<RetryCurrentQuestion>(_onRetryQuestion);
    on<RestartLevel>(_onRestartLevel);
    on<VocabularyHintUsed>(_onUseHint);
    on<RestoreLife>(_onRestoreLife);
    on<AddHint>(_onAddHint);
  }

  // ─────────────────────────────────────────────
  // FETCH QUESTS — O(n) dedup, O(n) space
  // ─────────────────────────────────────────────

  Future<void> _onFetchQuests(
    FetchVocabularyQuests event,
    Emitter<VocabularyState> emit,
  ) async {
    _currentGameType = event.gameType.name;
    _currentLevel = event.level;

    emit(const VocabularyLoading());

    //  Offline check before network call.
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      emit(
        const VocabularyError(
          'No internet connection. Please check your network and try again.',
          technicalError: 'NetworkInfo.isConnected returned false',
        ),
      );
      return;
    }

    try {
      final quests = await getQuests(event.gameType.name, event.level);

      if (quests.isEmpty) {
        emit(
          VocabularyError(
            "We couldn't find any quests for this level yet.",
            technicalError:
                'Empty quest list for category: ${event.gameType.name}, level: ${event.level}',
          ),
        );
        return;
      }

      // Dedup by id, preserve JSON order — O(n)
      final seen = <String>{};
      final unique = <VocabularyQuest>[];
      for (final q in quests) {
        if (seen.add(q.id)) unique.add(q);
      }

      final limited = unique
          .take(VocabularyRewardConstants.maxQuestsPerLevel)
          .toList();

      emit(
        VocabularyLoaded(
          quests: limited,
          currentIndex: 0,
          livesRemaining: VocabularyRewardConstants.initialLives,
        ),
      );
    } catch (e, stackTrace) {
      assert(() {
        debugPrint('[VocabularyBloc] _onFetchQuests: $e\n$stackTrace');
        return true;
      }());
      emit(
        VocabularyError(
          'Failed to load quests. Please try again.',
          technicalError: e.toString(),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // SUBMIT ANSWER — O(n) worst case (mastery loop append)
  // ─────────────────────────────────────────────

  Future<void> _onSubmitAnswer(
    SubmitAnswer event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    if (s.livesRemaining <= 0) return;

    if (event.isCorrect) {
      await soundService.playCorrect();
      await hapticService.success();
      emit(
        s.copyWith(
          lastAnswerCorrect: true,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    } else {
      await soundService.playWrong();
      await hapticService.error();

      final newLives = s.livesRemaining - 1;
      final newWrongCount = s.wrongCount + 1;
      final isFinal =
          newWrongCount >=
          VocabularyRewardConstants.wrongCountBeforeMasteryLoop;

      // Mastery Loop: append failed quest for second attempt
      final updatedQuests = isFinal ? [...s.quests, s.currentQuest] : s.quests;

      emit(
        s.copyWith(
          quests: updatedQuests,
          livesRemaining: newLives,
          lastAnswerCorrect: false,
          wrongCount: isFinal ? 0 : newWrongCount,
          isFinalFailure: isFinal || newLives <= 0,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // NEXT QUESTION — O(1)
  // ─────────────────────────────────────────────

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;

    if (s.livesRemaining <= 0) {
      emit(VocabularyGameOver(quests: s.quests, currentIndex: s.currentIndex));
      return;
    }

    final isOnLastQuest = s.currentIndex >= s.quests.length - 1;

    if (isOnLastQuest) {
      if (s.lastAnswerCorrect == true) {
        await _handleLevelComplete(s, emit);
      } else {
        emit(s.copyWith(clearLastAnswerCorrect: true, hintUsed: false));
      }
      return;
    }

    if (s.lastAnswerCorrect == true || s.isFinalFailure) {
      emit(
        s.copyWith(
          currentIndex: s.currentIndex + 1,
          clearLastAnswerCorrect: true,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );
    } else {
      emit(s.copyWith(clearLastAnswerCorrect: true, hintUsed: false));
    }
  }

  //  Emit completion state FIRST (UI unblocks immediately),
  // then run persistence in parallel via Future.wait.
  Future<void> _handleLevelComplete(
    VocabularyLoaded s,
    Emitter<VocabularyState> emit,
  ) async {
    soundService.playLevelComplete();

    const totalXp = VocabularyRewardConstants.baseXp;
    const totalCoins = VocabularyRewardConstants.baseCoins;

    emit(
      VocabularyGameComplete(
        xpEarned: totalXp,
        coinsEarned: totalCoins,
        questCount: s.quests.length,
      ),
    );

    if (_currentGameType != null && _currentLevel != null) {
      final gameType = _currentGameType!;
      final level = _currentLevel!;

      //  Parallel persistence — was sequential (4× latency).
      // FIX: .catchError uses _swallow which returns Either<Failure, void>
      // matching the use-case return type. Empty {} body was causing:
      // "onError handler must return Either<Failure, void>" compile error.
      await Future.wait([
        updateUserRewards(
          UpdateUserRewardsParams(
            gameType: gameType,
            level: level,
            xpIncrease: totalXp,
            coinIncrease: totalCoins,
          ),
        ).catchError(_swallow),
        updateCategoryStats(
          UpdateCategoryStatsParams(categoryId: gameType, isCorrect: true),
        ).catchError(_swallow),
        updateUnlockedLevel(
          UpdateUnlockedLevelParams(categoryId: gameType, newLevel: level + 1),
        ).catchError(_swallow),
        awardBadge(
          VocabularyRewardConstants.masteryBadgeId,
        ).catchError(_swallow),
      ]);
    }
  }

  // ─────────────────────────────────────────────
  // RETRY
  // ─────────────────────────────────────────────

  void _onRetryQuestion(
    RetryCurrentQuestion event,
    Emitter<VocabularyState> emit,
  ) {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    emit(s.copyWith(clearLastAnswerCorrect: true, hintUsed: false));
  }

  // ─────────────────────────────────────────────
  // RESTART
  // ─────────────────────────────────────────────

  Future<void> _onRestartLevel(
    RestartLevel event,
    Emitter<VocabularyState> emit,
  ) async {
    if (_currentGameType != null && _currentLevel != null) {
      // Safe firstWhere — orElse returns null instead of StateError.
      final matchedType = GameSubtype.values.cast<GameSubtype?>().firstWhere(
        (e) => e?.name == _currentGameType,
        orElse: () => null,
      );
      if (matchedType != null) {
        add(
          FetchVocabularyQuests(gameType: matchedType, level: _currentLevel!),
        );
      } else {
        emit(const VocabularyInitial());
      }
    } else {
      emit(const VocabularyInitial());
    }
  }

  // ─────────────────────────────────────────────
  // HINT
  // ─────────────────────────────────────────────

  Future<void> _onUseHint(
    VocabularyHintUsed event,
    Emitter<VocabularyState> emit,
  ) async {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    if (s.hintUsed) return;

    final result = await useHint(NoParams());
    //  Handle failure case explicitly — was silently ignored.
    result.fold(
      (_) {}, // Left — failure, no state change
      (_) {
        emit(s.copyWith(hintUsed: true));
        hapticService.selection();
      },
    );
  }

  // ─────────────────────────────────────────────
  // RESTORE LIFE (Revive)
  // ─────────────────────────────────────────────

  void _onRestoreLife(RestoreLife event, Emitter<VocabularyState> emit) {
    if (state is! VocabularyGameOver) return;
    final s = state as VocabularyGameOver;
    emit(
      VocabularyLoaded(
        quests: s.quests,
        currentIndex: s.currentIndex,
        livesRemaining: VocabularyRewardConstants.reviveLives,
        lastAnswerCorrect: null,
        hintUsed: false,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ADD HINT
  //  Was a complete no-op. Now updates hintsAvailable.
  // ─────────────────────────────────────────────

  void _onAddHint(AddHint event, Emitter<VocabularyState> emit) {
    if (state is! VocabularyLoaded) return;
    final s = state as VocabularyLoaded;
    emit(s.copyWith(hintsAvailable: s.hintsAvailable + event.count));
  }
}
