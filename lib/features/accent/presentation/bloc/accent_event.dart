part of 'accent_bloc.dart';

abstract class AccentEvent {}

class FetchAccentQuests extends AccentEvent {
  final GameSubtype gameType;
  final int level;
  FetchAccentQuests({required this.gameType, required this.level});
}

class SubmitAnswer extends AccentEvent {
  final bool? isCorrect;
  SubmitAnswer(this.isCorrect);
}

class NextQuestion extends AccentEvent {}

class RestartLevel extends AccentEvent {}

class AccentHintUsed extends AccentEvent {}

class RestoreLife extends AccentEvent {}

class PreloadBatch extends AccentEvent {
  final GameSubtype gameType;
  final int currentLevel;
  PreloadBatch({required this.gameType, required this.currentLevel});
}
