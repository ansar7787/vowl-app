import 'package:vowl/core/domain/entities/game_quest.dart';

abstract class GameStateBase {
  int get livesRemaining;
}

abstract class GameInitialState extends GameStateBase {}

abstract class GameLoadingState extends GameStateBase {}

abstract class GameLoadedState extends GameStateBase {
  int get currentIndex;
  bool? get lastAnswerCorrect;
  bool get hintUsed;
  bool get isFinalFailure;
  GameQuest? get currentQuestOrNull;

  // Total quests for progress calculation
  int get totalQuests;
}

abstract class GameErrorState extends GameStateBase {
  String get message;
}

abstract class GameOverState extends GameStateBase {}

abstract class GameCompleteState extends GameStateBase {
  int get xpEarned;
  int get coinsEarned;
}
