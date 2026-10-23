import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';

/// Base class for all grammar learning BLoC events.
abstract class GrammarEvent extends Equatable {
  /// Base const constructor for [GrammarEvent].
  const GrammarEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched to load grammar quests for [gameType] at [level].
class FetchGrammarQuests extends GrammarEvent {
  /// The grammar game subtype to fetch.
  final GameSubtype gameType;

  /// The level index to query.
  final int level;

  /// Creates a [FetchGrammarQuests] event.
  const FetchGrammarQuests({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Event dispatched when a user submits an answer to a trial.
class SubmitAnswer extends GrammarEvent {
  /// Whether the answer was evaluated as correct.
  final bool isCorrect;

  /// Creates a [SubmitAnswer] event with evaluation result [isCorrect].
  const SubmitAnswer(this.isCorrect);

  @override
  List<Object?> get props => [isCorrect];
}

/// Event dispatched to navigate to the next question or complete the level.
class NextQuestion extends GrammarEvent {
  /// Creates a [NextQuestion] event.
  const NextQuestion();
}

/// Event dispatched to re-attempt the active question after an incorrect answer.
class RetryCurrentQuestion extends GrammarEvent {
  /// Creates a [RetryCurrentQuestion] event.
  const RetryCurrentQuestion();
}

/// Event dispatched to reset and reload the current level.
class RestartLevel extends GrammarEvent {
  /// Creates a [RestartLevel] event.
  const RestartLevel();
}

/// Event dispatched when a user consumes a pedagogical hint.
class GrammarHintUsed extends GrammarEvent {
  /// Creates a [GrammarHintUsed] event.
  const GrammarHintUsed();
}

/// Event dispatched to replenish a lost life.
class RestoreLife extends GrammarEvent {
  /// Creates a [RestoreLife] event.
  const RestoreLife();
}

/// Event dispatched to preload a future batch of grammar quests in background.
class PreloadGrammarBatch extends GrammarEvent {
  /// The target grammar game subtype.
  final GameSubtype gameType;

  /// The level index to preload.
  final int level;

  /// Creates a [PreloadGrammarBatch] event.
  const PreloadGrammarBatch({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}
