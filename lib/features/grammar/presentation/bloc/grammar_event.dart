import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';

abstract class GrammarEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchGrammarQuests extends GrammarEvent {
  final GameSubtype gameType;
  final int level;
  FetchGrammarQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitAnswer extends GrammarEvent {
  final bool isCorrect;
  SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextQuestion extends GrammarEvent {}

class RetryCurrentQuestion extends GrammarEvent {}

class RestartLevel extends GrammarEvent {}

class GrammarHintUsed extends GrammarEvent {}

class RestoreLife extends GrammarEvent {}

class PreloadGrammarBatch extends GrammarEvent {
  final GameSubtype gameType;
  final int level;
  PreloadGrammarBatch({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}
