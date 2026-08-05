import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';

/// All events that [ListeningBloc] can process.
///
/// Every event is immutable and uses a `const` constructor.
/// [FetchListeningQuests] now accepts a typed [GameSubtype] instead of
/// `dynamic`, eliminating the string-to-subtype conversion inside the bloc
/// and making callers responsible for type resolution (correct layer boundary).
abstract class ListeningEvent extends Equatable {
  const ListeningEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches quests for [gameType] and [level] from the data layer.
class FetchListeningQuests extends ListeningEvent {
  /// Strongly-typed subtype — no more `dynamic` or string fallback.
  final GameSubtype gameType;
  final int level;

  const FetchListeningQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Player has selected or confirmed an answer.
class SubmitAnswer extends ListeningEvent {
  final bool isCorrect;

  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Player taps Continue / Try Again / See Results.
class NextQuestion extends ListeningEvent {
  const NextQuestion();
}

/// Resets the current question to its unanswered state so the player can
/// re-attempt after a first wrong answer.
class RetryCurrentQuestion extends ListeningEvent {
  const RetryCurrentQuestion();
}

/// Player activated a hint for the current question.
class ListeningHintUsed extends ListeningEvent {
  const ListeningHintUsed();
}

/// Player chose to restore a life (rewarded ad / coin spend).
class RestoreLife extends ListeningEvent {
  const RestoreLife();
}

/// Resets the bloc to [ListeningInitial] so a fresh fetch can be triggered.
class RestartLevel extends ListeningEvent {
  const RestartLevel();
}

class ListeningSpeakConfirmed extends ListeningEvent {
  final int bonusCoins;
  const ListeningSpeakConfirmed(this.bonusCoins);
  @override
  List<Object?> get props => [bonusCoins];
}
