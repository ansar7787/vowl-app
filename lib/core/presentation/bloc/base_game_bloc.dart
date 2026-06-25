import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// ---------------------------------------------------------------------------
// SENTINEL — Distinguishes "explicitly passed null" from "not supplied" in
// nullable copyWith parameters. Standard Dart nullable-override idiom.
// ---------------------------------------------------------------------------
class _Unset {
  const _Unset();
}

const _unset = _Unset();

// ---------------------------------------------------------------------------
// BASE STATES
// ---------------------------------------------------------------------------

/// Root state for all game BLoCs. Subclasses extend via concrete generics.
abstract class BaseGameState extends Equatable {
  final int lives;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final bool isComplete;

  const BaseGameState({
    this.lives = 3,
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.isComplete = false,
  });

  @override
  List<Object?> get props => [
    lives,
    currentIndex,
    isLoading,
    error,
    isComplete,
  ];
}

class GameInitial extends BaseGameState {
  const GameInitial() : super();
}

class GameLoading extends BaseGameState {
  const GameLoading() : super(isLoading: true);
}

class GameActive<T extends GameQuest> extends BaseGameState {
  final List<T> quests;

  /// `null` = question not yet answered; `true`/`false` = last result.
  final bool? lastAnswerCorrect;
  final bool hintUsed;

  T get currentQuest => quests[currentIndex];

  const GameActive({
    required this.quests,
    super.lives = 3,
    super.currentIndex = 0,
    this.lastAnswerCorrect,
    this.hintUsed = false,
  });

  GameActive<T> copyWith({
    List<T>? quests,
    int? lives,
    int? currentIndex,
    // Pass `_unset` to keep current value; pass `null` to explicitly clear it.
    Object? lastAnswerCorrect = _unset,
    bool? hintUsed,
  }) {
    return GameActive<T>(
      quests: quests ?? this.quests,
      lives: lives ?? this.lives,
      currentIndex: currentIndex ?? this.currentIndex,
      lastAnswerCorrect: lastAnswerCorrect == _unset
          ? this.lastAnswerCorrect
          : (lastAnswerCorrect as bool?),
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    quests,
    lastAnswerCorrect,
    hintUsed,
  ];
}

class GameError extends BaseGameState {
  const GameError(String message) : super(error: message);
}

class GameComplete extends BaseGameState {
  final int xpEarned;
  final int coinsEarned;

  const GameComplete({required this.xpEarned, required this.coinsEarned})
    : super(isComplete: true);

  @override
  List<Object?> get props => [...super.props, xpEarned, coinsEarned];
}

class GameOver extends BaseGameState {
  const GameOver() : super(lives: 0);
}

// ---------------------------------------------------------------------------
// BASE EVENTS
// ---------------------------------------------------------------------------

abstract class BaseGameEvent extends Equatable {
  const BaseGameEvent();

  @override
  List<Object?> get props => const [];
}

class LoadGame extends BaseGameEvent {
  final GameSubtype subtype;
  final int level;

  const LoadGame(this.subtype, this.level);

  @override
  List<Object?> get props => [subtype, level];
}

class SubmitGameAnswer extends BaseGameEvent {
  final bool isCorrect;

  const SubmitGameAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextGameQuestion extends BaseGameEvent {
  const NextGameQuestion();
}

class RestartGameLevel extends BaseGameEvent {
  const RestartGameLevel();
}

// ---------------------------------------------------------------------------
// BASE BLOC
// ---------------------------------------------------------------------------

/// Abstract base for all game-category BLoCs.
///
/// Subclasses implement [fetchQuests] for curriculum resolution and
/// [onLevelComplete] for XP/coin persistence. All shared lifecycle logic
/// (loading, answer evaluation, question progression, completion) lives here.
abstract class BaseGameBloc<T extends GameQuest>
    extends Bloc<BaseGameEvent, BaseGameState> {
  BaseGameBloc() : super(const GameInitial()) {
    on<LoadGame>(_onLoadGame);
    on<SubmitGameAnswer>(_onSubmitAnswer);
    on<NextGameQuestion>(_onNextQuestion);
    on<RestartGameLevel>((_, emit) => emit(const GameInitial()));
  }

  /// Fetch the ordered quest list for the given [subtype] + [level].
  Future<List<T>> fetchQuests(GameSubtype subtype, int level);

  /// Persist XP/coin rewards after a successful level completion.
  /// Errors are caught and logged internally — never propagated to UI.
  Future<void> onLevelComplete(int xp, int coins);

  // ─── Handlers ────────────────────────────────────────────────────────────

  Future<void> _onLoadGame(LoadGame event, Emitter<BaseGameState> emit) async {
    // Defensive guard: prevents double-load race conditions.
    if (state is GameLoading) return;

    emit(const GameLoading());
    try {
      final quests = await fetchQuests(event.subtype, event.level);
      if (quests.isEmpty) {
        emit(const GameError('No quests found for this level.'));
      } else {
        emit(GameActive<T>(quests: quests));
      }
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  Future<void> _onSubmitAnswer(
    SubmitGameAnswer event,
    Emitter<BaseGameState> emit,
  ) async {
    if (state is! GameActive<T>) return;
    final s = state as GameActive<T>;

    final newLives = event.isCorrect ? s.lives : s.lives - 1;

    if (newLives <= 0) {
      emit(const GameOver());
    } else {
      emit(s.copyWith(lives: newLives, lastAnswerCorrect: event.isCorrect));
    }
  }

  Future<void> _onNextQuestion(
    NextGameQuestion event,
    Emitter<BaseGameState> emit,
  ) async {
    if (state is! GameActive<T>) return;
    final s = state as GameActive<T>;

    if (s.lastAnswerCorrect == true) {
      final isLastQuestion = s.currentIndex + 1 >= s.quests.length;

      if (!isLastQuestion) {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
          ),
        );
      } else {
        // Level complete — accumulate rewards before notifying UI.
        final xp = s.quests.fold(0, (sum, q) => sum + q.xpReward);
        final coins = s.quests.fold(0, (sum, q) => sum + q.coinReward);

        try {
          await onLevelComplete(xp, coins);
        } catch (_) {
          // Reward persistence failure must not block the UX transition.
        }

        emit(GameComplete(xpEarned: xp, coinsEarned: coins));
      }
    } else {
      // Wrong answer — clear the result flag so the UI resets.
      emit(s.copyWith(lastAnswerCorrect: null));
    }
  }
}
