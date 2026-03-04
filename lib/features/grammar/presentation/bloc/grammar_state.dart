import '../../domain/entities/grammar_quest.dart';

abstract class GrammarState {}

class GrammarInitial extends GrammarState {}

class GrammarLoading extends GrammarState {}

class GrammarLoaded extends GrammarState {
  final List<GrammarQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;

  GrammarQuest get currentQuest => quests[currentIndex];

  GrammarLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.hintUsed = false,
  });

  GrammarLoaded copyWith({
    List<GrammarQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
  }) {
    return GrammarLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: lastAnswerCorrect,
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class GrammarError extends GrammarState {
  final String message;
  GrammarError(this.message);
}

class GrammarGameComplete extends GrammarState {
  final int xpEarned;
  final int coinsEarned;
  GrammarGameComplete({required this.xpEarned, required this.coinsEarned});
}

class GrammarGameOver extends GrammarState {
  final List<GrammarQuest> quests;
  final int currentIndex;

  GrammarGameOver({required this.quests, required this.currentIndex});
}
