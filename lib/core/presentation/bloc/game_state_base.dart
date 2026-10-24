import 'package:vowl/core/domain/entities/game_quest.dart';

/// Foundational base contract for all interactive activity states.
abstract class GameStateBase {
  /// Remaining attempt lives for the active game session.
  int get livesRemaining;
}

/// Initializing state before data loading or configuration begins.
abstract class GameInitialState extends GameStateBase {}

/// Loading state while quest assets and questions are fetched or prepared.
abstract class GameLoadingState extends GameStateBase {}

/// Active gameplay state containing the current question index, answers, and progress.
abstract class GameLoadedState extends GameStateBase {
  /// Zero-based index of the currently active quest item.
  int get currentIndex;

  /// Whether the most recent submitted answer was correct (`null` if unanswered).
  bool? get lastAnswerCorrect;

  /// Whether a hint was used for the current question.
  bool get hintUsed;

  /// Whether all remaining retry lives are exhausted for this question.
  bool get isFinalFailure;

  /// The active [GameQuest] being presented, or `null` if none is loaded.
  GameQuest? get currentQuestOrNull;

  /// Total count of quest questions in this game session.
  int get totalQuests;
}

/// Error state when activity initialization or execution fails unexpectedly.
abstract class GameErrorState extends GameStateBase {
  /// Localized error description or diagnostic message.
  String get message;
}

/// Game over state triggered when the user exhausts all remaining lives.
abstract class GameOverState extends GameStateBase {}

/// Completion state triggered when all quests in the level are successfully resolved.
abstract class GameCompleteState extends GameStateBase {
  /// Total experience points awarded for completing the level.
  int get xpEarned;

  /// Total virtual coins awarded for completing the level.
  int get coinsEarned;
}
