part of 'elite_mastery_bloc.dart';

abstract class EliteMasteryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EliteMasteryInitial extends EliteMasteryState {}

class EliteMasteryLoading extends EliteMasteryState {}

class EliteMasteryLoaded extends EliteMasteryState {
  final List<EliteMasteryQuest> quests;
  final int currentIndex;
  final int livesRemaining;
  final bool? lastAnswerCorrect;
  final bool isHintVisible;
  final bool isHintUsed;
  final int wrongCount;
  final bool isFinalFailure;

  EliteMasteryQuest get currentQuest => quests[currentIndex];

  EliteMasteryLoaded({
    required this.quests,
    required this.currentIndex,
    required this.livesRemaining,
    this.lastAnswerCorrect,
    this.isHintVisible = false,
    this.isHintUsed = false,
    this.wrongCount = 0,
    this.isFinalFailure = false,
  });

  @override
  List<Object?> get props => [quests, currentIndex, livesRemaining, lastAnswerCorrect, isHintVisible, isHintUsed, wrongCount, isFinalFailure];

  EliteMasteryLoaded copyWith({
    List<EliteMasteryQuest>? quests,
    int? currentIndex,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool? isHintVisible,
    bool? isHintUsed,
    int? wrongCount,
    bool? isFinalFailure,
    bool resetLastAnswer = false,
  }) {
    return EliteMasteryLoaded(
      quests: quests ?? this.quests,
      currentIndex: currentIndex ?? this.currentIndex,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect: resetLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      isHintVisible: isHintVisible ?? this.isHintVisible,
      isHintUsed: isHintUsed ?? this.isHintUsed,
      wrongCount: wrongCount ?? this.wrongCount,
      isFinalFailure: isFinalFailure ?? this.isFinalFailure,
    );
  }
}

class EliteMasteryError extends EliteMasteryState {
  final String message;
  EliteMasteryError(this.message);

  @override
  List<Object?> get props => [message];
}

class EliteMasteryGameComplete extends EliteMasteryState {
  final int xpEarned;
  final int coinsEarned;
  final int questCount;
  EliteMasteryGameComplete({
    required this.xpEarned,
    required this.coinsEarned,
    required this.questCount,
  });

  @override
  List<Object?> get props => [xpEarned, coinsEarned, questCount];
}

class EliteMasteryGameOver extends EliteMasteryState {
  final List<EliteMasteryQuest> quests;
  final int currentIndex;
  EliteMasteryGameOver({required this.quests, required this.currentIndex});

  @override
  List<Object?> get props => [quests, currentIndex];
}
