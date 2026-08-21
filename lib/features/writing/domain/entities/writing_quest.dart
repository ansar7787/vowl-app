import 'package:vowl/core/domain/entities/game_quest.dart';

class WritingQuest extends GameQuest {
  final String? passage;
  final String? missingWord;
  final String? prompt;
  final String? sampleAnswer;
  final List<String>? shuffledWords;
  final List<int>? correctOrder;
  final String? story;
  final String? situation;
  final String? prefix;
  final String? suffix;
  final int? minWords;
  final List<String>? requiredPoints;
  final String? dayDescription;
  final String? context;
  final String? partialSentence;
  final String? completion;
  final String? subject;
  final String? recipient;
  final String? essayTopic;
  final List<String>? emojis;
  final Map<String, List<String>>? keywords;
  final int? errorCount;
  final List<String>? promptQuestions;
  final String? modelAnswer;
  final String? thesisStatement;
  final String? errorType;
  final String? structureGuide;
  final List<String>? storyKeyEvents;
  final String? formalityLevel;
  final String? sentenceType;
  final String? grammarFocus;
  final List<String>? keywordsExpected;

  const WritingQuest({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.writing,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    this.passage,
    super.question,
    super.textToSpeak,
    super.visualConfig,
    this.missingWord,
    this.prompt,
    this.sampleAnswer,
    super.explanation,
    this.shuffledWords,
    this.correctOrder,
    this.story,
    this.situation,
    this.prefix,
    this.suffix,
    this.minWords,
    this.requiredPoints,
    this.dayDescription,
    this.context,
    this.partialSentence,
    this.completion,
    this.subject,
    this.recipient,
    this.essayTopic,
    this.emojis,
    this.keywords,
    this.errorCount,
    this.promptQuestions,
    this.modelAnswer,
    this.thesisStatement,
    this.errorType,
    this.structureGuide,
    this.storyKeyEvents,
    this.formalityLevel,
    this.sentenceType,
    this.grammarFocus,
    this.keywordsExpected,
  });

  String? get incorrectSentence => passage;
  String? get correctSentence => correctAnswer;
}
