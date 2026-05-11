import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

// --- BASE STATES ---
abstract class BaseGameState {
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
}

class GameInitial extends BaseGameState {
  const GameInitial() : super();
}

class GameLoading extends BaseGameState {
  const GameLoading() : super(isLoading: true);
}

class GameActive<T extends GameQuest> extends BaseGameState {
  final List<T> quests;
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
    bool? lastAnswerCorrect,
    bool? hintUsed,
  }) {
    return GameActive<T>(
      quests: quests ?? this.quests,
      lives: lives ?? this.lives,
      currentIndex: currentIndex ?? this.currentIndex,
      lastAnswerCorrect: lastAnswerCorrect, // Nullable override
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class GameError extends BaseGameState {
  const GameError(String message) : super(error: message);
}

class GameComplete extends BaseGameState {
  final int xpEarned;
  final int coinsEarned;
  const GameComplete({required this.xpEarned, required this.coinsEarned})
    : super(isComplete: true);
}

class GameOver extends BaseGameState {
  const GameOver() : super(lives: 0);
}

// --- BASE EVENTS ---
abstract class BaseGameEvent {}

class LoadGame extends BaseGameEvent {
  final GameSubtype subtype;
  final int level;
  LoadGame(this.subtype, this.level);
}

class SubmitGameAnswer extends BaseGameEvent {
  final bool isCorrect;
  SubmitGameAnswer(this.isCorrect);
}

class NextGameQuestion extends BaseGameEvent {}

class RestartGameLevel extends BaseGameEvent {}

// --- BASE BLOC ---
abstract class BaseGameBloc<T extends GameQuest>
    extends Bloc<BaseGameEvent, BaseGameState> {
  BaseGameBloc() : super(const GameInitial());

  // Subclasses implement these
  Future<List<T>> fetchQuests(GameSubtype subtype, int level);
  Future<void> onLevelComplete(int xp, int coins);

  void registerEvents() {
    on<LoadGame>(_onLoadGame);
    on<SubmitGameAnswer>(_onSubmitAnswer);
    on<NextGameQuestion>(_onNextQuestion);
    on<RestartGameLevel>((event, emit) => emit(const GameInitial()));
  }

  Future<void> _onLoadGame(LoadGame event, Emitter<BaseGameState> emit) async {
    emit(const GameLoading());
    try {
      final quests = await fetchQuests(event.subtype, event.level);
      if (quests.isEmpty) {
        emit(const GameError("No quests found for this level."));
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

    int newLives = s.lives;
    if (!event.isCorrect) {
      newLives--;
    }

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
      if (s.currentIndex + 1 < s.quests.length) {
        emit(
          s.copyWith(
            currentIndex: s.currentIndex + 1,
            lastAnswerCorrect: null,
            hintUsed: false,
          ),
        );
      } else {
        final xp = s.quests.fold(0, (sum, q) => sum + q.xpReward);
        final coins = s.quests.fold(0, (sum, q) => sum + q.coinReward);
        await onLevelComplete(xp, coins);
        emit(GameComplete(xpEarned: xp, coinsEarned: coins));
      }
    } else {
      emit(s.copyWith(lastAnswerCorrect: null));
    }
  }
}
