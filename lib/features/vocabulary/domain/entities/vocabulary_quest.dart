import 'package:vowl/core/domain/entities/game_quest.dart';

class VocabularyQuest extends GameQuest {
  final String? word;
  final String? definition;
  final String? synonym;
  final String? antonym;
  final String? contextSentence;
  final String? prompt;
  final String? explanation;
  final String? audioUrl;
  final String? passage;
  final List<String>? synonyms;
  final List<String>? antonyms;

  const VocabularyQuest({
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
    this.word,
    this.definition,
    this.synonym,
    this.antonym,
    this.contextSentence,
    this.prompt,
    super.textToSpeak,
    super.visualConfig,
    this.explanation,
    this.audioUrl,
    this.passage,
    this.synonyms,
    this.antonyms,
    this.topicEmoji,
    this.topicFact,
    this.rootWord,
    this.prefix,
    this.suffix,
    this.topicBuckets,
  });

  final String? rootWord;
  final String? prefix;
  final String? suffix;
  final List<String>? topicBuckets;
  final String? topicEmoji;
  final String? topicFact;

  String? get sentence => contextSentence ?? passage;
  String? get question => instruction;
  String? get targetWord => word;
  String? get example => contextSentence ?? explanation;
  String? get meaning => definition;
}

