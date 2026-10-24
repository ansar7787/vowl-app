part of 'elite_mastery_bloc.dart';

/// Base class for all events dispatched to [EliteMasteryBloc].
abstract class EliteMasteryEvent extends Equatable {
  /// Const base constructor for elite mastery events.
  const EliteMasteryEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load quest definitions for a given [gameType] and [level].
class FetchEliteMasteryQuests extends EliteMasteryEvent {
  /// Specific subgame type to load.
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Creates a [FetchEliteMasteryQuests] event.
  const FetchEliteMasteryQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Dispatched when the player submits an answer evaluation.
class SubmitEliteAnswer extends EliteMasteryEvent {
  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// Creates a [SubmitEliteAnswer] event.
  const SubmitEliteAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Dispatched to advance to the next question in the active level.
class NextEliteQuestion extends EliteMasteryEvent {
  /// Creates a [NextEliteQuestion] event.
  const NextEliteQuestion();
}

/// Dispatched to reset and retry the current question after a mistake.
class RetryEliteQuestion extends EliteMasteryEvent {
  /// Creates a [RetryEliteQuestion] event.
  const RetryEliteQuestion();
}

/// Dispatched to restore player lives using consumables.
class RestoreEliteLife extends EliteMasteryEvent {
  /// Creates a [RestoreEliteLife] event.
  const RestoreEliteLife();
}

/// Dispatched when a hint request is triggered.
class ShowEliteHint extends EliteMasteryEvent {
  /// Creates a [ShowEliteHint] event.
  const ShowEliteHint();
}

/// Dispatched after a hint has been displayed and consumed.
class MarkEliteHintUsed extends EliteMasteryEvent {
  /// Creates a [MarkEliteHintUsed] event.
  const MarkEliteHintUsed();
}

/// Dispatched to grant an extra life following a rewarded advertisement view.
class AddLifeFromAd extends EliteMasteryEvent {
  /// Creates an [AddLifeFromAd] event.
  const AddLifeFromAd();
}

/// Dispatched when speech recognition confirms correct pronunciation.
class EliteSpeakConfirmed extends EliteMasteryEvent {
  /// Bonus coin incentive awarded for verbal participation.
  final int bonusCoins;

  /// Creates an [EliteSpeakConfirmed] event.
  const EliteSpeakConfirmed(this.bonusCoins);

  @override
  List<Object?> get props => [bonusCoins];
}
