part of 'elite_mastery_bloc.dart';

abstract class EliteMasteryEvent extends Equatable {
  const EliteMasteryEvent();

  @override
  List<Object?> get props => [];
}

class FetchEliteMasteryQuests extends EliteMasteryEvent {
  final GameSubtype gameType;
  final int level;

  const FetchEliteMasteryQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class SubmitEliteAnswer extends EliteMasteryEvent {
  final bool isCorrect;

  const SubmitEliteAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

class NextEliteQuestion extends EliteMasteryEvent {
  const NextEliteQuestion();
}

class RetryEliteQuestion extends EliteMasteryEvent {
  const RetryEliteQuestion();
}

class RestoreEliteLife extends EliteMasteryEvent {
  const RestoreEliteLife();
}

class ShowEliteHint extends EliteMasteryEvent {
  const ShowEliteHint();
}

class MarkEliteHintUsed extends EliteMasteryEvent {
  const MarkEliteHintUsed();
}

class AddLifeFromAd extends EliteMasteryEvent {
  const AddLifeFromAd();
}

class EliteTutorPass extends EliteMasteryEvent {
  const EliteTutorPass();
}

class EliteSpeakConfirmed extends EliteMasteryEvent {
  final int bonusCoins;
  const EliteSpeakConfirmed(this.bonusCoins);
  @override
  List<Object?> get props => [bonusCoins];
}
