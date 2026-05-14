part of 'elite_mastery_bloc.dart';

abstract class EliteMasteryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchEliteMasteryQuests extends EliteMasteryEvent {
  final GameSubtype gameType;
  final int level;
  FetchEliteMasteryQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitEliteAnswer extends EliteMasteryEvent {
  final bool isCorrect;
  SubmitEliteAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextEliteQuestion extends EliteMasteryEvent {}

class RetryEliteQuestion extends EliteMasteryEvent {}

class RestoreEliteLife extends EliteMasteryEvent {}

class ShowEliteHint extends EliteMasteryEvent {}
class MarkEliteHintUsed extends EliteMasteryEvent {}

class AddLifeFromAd extends EliteMasteryEvent {}

class EliteTutorPass extends EliteMasteryEvent {}
