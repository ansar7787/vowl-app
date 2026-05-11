import 'package:vowl/core/domain/entities/game_quest.dart';

class EliteMasteryQuest extends GameQuest {
  final List<String>? sentences;
  final List<int>? correctOrder;
  final String? idiom;
  final String? word;
  final double? speedMultiplier;
  final String? audioUrl;
  final String? text;

  const EliteMasteryQuest({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.choice,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.textToSpeak,
    super.visualConfig,
    this.sentences,
    this.correctOrder,
    this.idiom,
    this.word,
    this.speedMultiplier,
    this.audioUrl,
    this.text,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        sentences,
        correctOrder,
        idiom,
        word,
        speedMultiplier,
        audioUrl,
        text,
      ];
}
