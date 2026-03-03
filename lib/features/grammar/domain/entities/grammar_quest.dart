import 'package:voxai_quest/core/domain/entities/game_quest.dart';

class GrammarQuest extends GameQuest {
  final String? sentence;
  final String? missingWord;
  final String? incorrectPart;
  final String? correctedPart;
  final List<String>? shuffledWords;
  final List<int>? correctOrder;
  final String? explanation;
  final String? prompt;
  final String? verb;
  final String? word;
  final String? targetTense;
  final String? secondarySentence;
  final String? firstClause;
  final String? secondClause;
  final String? connectorToUse;
  final String? sentenceWithBlank;
  final String? articleToInsert;
  final String? targetWord;
  final String? passage;
  final String? passiveSentence;
  final String? activeSentence;

  const GrammarQuest({
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
    this.sentence,
    this.missingWord,
    this.incorrectPart,
    this.correctedPart,
    this.shuffledWords,
    this.correctOrder,
    this.explanation,
    this.prompt,
    super.textToSpeak,
    this.verb,
    this.word,
    this.targetTense,
    this.secondarySentence,
    this.firstClause,
    this.secondClause,
    this.connectorToUse,
    this.sentenceWithBlank,
    this.articleToInsert,
    this.targetWord,
    this.passage,
    this.passiveSentence,
    this.activeSentence,
  });

  String? get question =>
      passage ?? sentence ?? sentenceWithBlank ?? passiveSentence ?? prompt;
  String? get correctSentence => correctAnswer ?? activeSentence ?? missingWord;

  @override
  List<Object?> get props => [
    ...super.props,
    sentence,
    missingWord,
    incorrectPart,
    correctedPart,
    shuffledWords,
    correctOrder,
    explanation,
    prompt,
    verb,
    word,
    targetTense,
    secondarySentence,
    firstClause,
    secondClause,
    connectorToUse,
    sentenceWithBlank,
    articleToInsert,
    targetWord,
    passage,
    passiveSentence,
    activeSentence,
  ];
}
