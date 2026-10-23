import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing a vocabulary quest or challenge within the vocabulary learning system.
class VocabularyQuest extends GameQuest {
  /// The target vocabulary word or lexical item.
  final String? word;

  /// The definition or semantic explanation of the target word.
  final String? definition;

  /// Primary synonym for the target word.
  final String? synonym;

  /// Primary antonym for the target word.
  final String? antonym;

  /// Contextual sentence illustrating proper grammatical and semantic usage.
  final String? contextSentence;

  /// Prompt or instructional query posed to the learner.
  final String? prompt;

  /// Reading passage containing the lexical item in rich context.
  final String? passage;

  /// Collection of valid synonyms for the target word.
  final List<String>? synonyms;

  /// Collection of valid antonyms for the target word.
  final List<String>? antonyms;

  /// Concrete usage example highlighting collocation or register.
  final String? usageExample;

  /// Explicit explanation detailing subtle nuances between near-synonyms.
  final String? nuanceDifference;

  /// Ordered scale representing intensity, formality, or connotation spectrum.
  final List<String>? gradientScale;

  /// Semantic classification of context clues (e.g., contrast, definition, example).
  final String? clueType;

  /// Specific words within the passage serving as contextual clues.
  final List<String>? evidenceWords;

  /// Comparison elucidating figurative idiom versus literal interpretation.
  final String? literalVsFigurative;

  /// Etymological history, cultural genesis, or figurative origin of an idiom.
  final String? origin;

  /// Scholarly domain or academic discipline where this lexical item predominates.
  final String? academicField;

  /// Common word partnerships or habitual co-occurrences.
  final List<String>? collocations;

  /// Semantically or thematically related lexical items.
  final List<String>? relatedWords;

  /// Morphological variants forming the derivational word family.
  final List<String>? familyTree;

  /// Detailed analysis dissecting morphemic, grammatical, or semantic roots.
  final String? meaningBreakdown;

  /// Erroneous or unnatural collocations presented as distractors.
  final List<String>? wrongCollocations;

  /// Formality rating or register classification index.
  final int? registerLevel;

  /// Morphological root word upon which affixes are applied.
  final String? rootWord;

  /// Bound morpheme prefixed to the base word.
  final String? prefix;

  /// Bound morpheme suffixed to the base word.
  final String? suffix;

  /// Thematic containment categories or categorical classification bins.
  final List<String>? topicBuckets;

  /// Graphical emoji symbol visually representing the topic domain.
  final String? topicEmoji;

  /// Informational fact or trivia pertaining to the vocabulary topic.
  final String? topicFact;

  /// Creates a [VocabularyQuest] entity.
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
    super.explanation,
    this.passage,
    this.synonyms,
    this.antonyms,
    this.topicEmoji,
    this.topicFact,
    this.rootWord,
    this.prefix,
    this.suffix,
    this.topicBuckets,
    this.usageExample,
    this.nuanceDifference,
    this.gradientScale,
    this.clueType,
    this.evidenceWords,
    this.literalVsFigurative,
    this.origin,
    this.academicField,
    this.collocations,
    this.relatedWords,
    this.familyTree,
    this.meaningBreakdown,
    this.wrongCollocations,
    this.registerLevel,
  });

  @override
  String? get sentence => contextSentence ?? passage;
  @override
  String? get question => instruction;
  @override
  String? get targetWord => word;

  /// Illustrative contextual sentence or instructional explanation.
  String? get example => contextSentence ?? explanation;

  /// Lexical definition of the quest's target word.
  String? get meaning => definition;

  @override
  List<Object?> get props => [
    ...super.props,
    word,
    definition,
    synonym,
    antonym,
    contextSentence,
    prompt,
    passage,
    synonyms,
    antonyms,
    usageExample,
    nuanceDifference,
    gradientScale,
    clueType,
    evidenceWords,
    literalVsFigurative,
    origin,
    academicField,
    collocations,
    relatedWords,
    familyTree,
    meaningBreakdown,
    wrongCollocations,
    registerLevel,
    rootWord,
    prefix,
    suffix,
    topicBuckets,
    topicEmoji,
    topicFact,
  ];
}
