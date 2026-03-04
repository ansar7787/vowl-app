part of 'accent_bloc.dart';

abstract class AccentState {
  const AccentState();
}

class AccentInitial extends AccentState {}

class AccentLoading extends AccentState {}

class AccentLoaded extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final GameSubtype gameType;
  final int level;

  AccentQuest get currentQuest => quests[currentIndex];

  AccentLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    required this.gameType,
    required this.level,
    this.lastAnswerCorrect,
    this.hintUsed = false,
  });

  AccentLoaded copyWith({
    List<AccentQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    GameSubtype? gameType,
    int? level,
  }) {
    return AccentLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class AccentError extends AccentState {
  final String message;
  AccentError(this.message);
}

class AccentGameComplete extends AccentState {
  final int xpEarned;
  final int coinsEarned;
  final AccentLoaded lastState;
  const AccentGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.lastState,
  });
}

class AccentGameOver extends AccentState {
  final List<AccentQuest> quests;
  final int currentIndex;
  final GameSubtype gameType;
  final int level;
  AccentGameOver({
    required this.quests,
    required this.currentIndex,
    required this.gameType,
    required this.level,
  });
}
