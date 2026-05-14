import 'package:equatable/equatable.dart';
import '../../domain/entities/grammar_quest.dart';

abstract class GrammarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GrammarInitial extends GrammarState {}

class GrammarLoading extends GrammarState {}

class GrammarLoaded extends GrammarState {
  final List<GrammarQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool hintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  GrammarQuest get currentQuest => quests[currentIndex];

  GrammarLoaded({
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

  GrammarLoaded copyWith({
    List<GrammarQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? hintUsed,
    int? wrongCount,
    bool? isFinalFailure,
  }) {
    return GrammarLoaded(
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

class GrammarError extends GrammarState {
  final String message;
  final String? technicalError;
  GrammarError(this.message, {this.technicalError});

  @override
  List<Object?> get props => [message, technicalError];
}

class GrammarGameComplete extends GrammarState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  GrammarGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class GrammarGameOver extends GrammarState {
  final List<GrammarQuest> quests;
  final int currentIndex;

  GrammarGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
