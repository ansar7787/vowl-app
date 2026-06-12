import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';

abstract class GrammarEvent extends Equatable {
  const GrammarEvent();

  @override
  List<Object?> get props => [];
}

class FetchGrammarQuests extends GrammarEvent {
  final GameSubtype gameType;
  final int level;

  const FetchGrammarQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends GrammarEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends GrammarEvent {
  const NextQuestion();
}

class RetryCurrentQuestion extends GrammarEvent {
  const RetryCurrentQuestion();
}

class RestartLevel extends GrammarEvent {
  const RestartLevel();
}

class GrammarHintUsed extends GrammarEvent {
  const GrammarHintUsed();
}

class RestoreLife extends GrammarEvent {
  const RestoreLife();
}

class PreloadGrammarBatch extends GrammarEvent {
  final GameSubtype gameType;
  final int level;

  const PreloadGrammarBatch({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}
