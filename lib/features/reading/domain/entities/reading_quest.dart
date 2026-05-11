import 'package:vowl/core/domain/entities/game_quest.dart';

class ReadingQuest extends GameQuest {
  final String? passage;
  final String? question;
  final String? highlightedWord;
  final String? statement;
  final List<String>? shuffledSentences;
  final List<int>? correctOrder;
  final List<Map<String, String>>? pairs;
  final String? phoneticHint;
  final String? targetWord;
  final String? explanation;
  final String? prompt;
  final List<String>? keywords;
  final int? timeLimit;
  final String? targetItem;

  const ReadingQuest({
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
    this.passage,
    this.question,
    this.highlightedWord,
    this.statement,
    this.shuffledSentences,
    this.correctOrder,
    this.pairs,
    this.phoneticHint,
    this.targetWord,
    this.explanation,
    super.textToSpeak,
    super.visualConfig,
    this.prompt,
    this.keywords,
    this.timeLimit,
    this.targetItem,
  });

  String? get word => targetWord ?? highlightedWord;
}

