import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing a grammar learning exercise quest item.
class GrammarQuest extends GameQuest {
  /// The missing word token in fill-in-the-blank trials.
  final String? missingWord;

  /// The erroneous grammatical substring to detect.
  final String? incorrectPart;

  /// The grammatically corrected replacement substring.
  final String? correctedPart;

  /// Shuffled word tokens to reorder syntactically.
  final List<String>? shuffledWords;

  /// Correct zero-based index order for [shuffledWords].
  final List<int>? correctOrder;

  /// Contextual prompt or instruction cue.
  final String? prompt;

  /// Grammatical subject of the active sentence.
  final String? subject;

  /// Target verb being conjugated or analyzed.
  final String? verb;

  /// Target word token under evaluation.
  final String? word;

  /// Target verb tense (e.g., 'past simple', 'present continuous').
  final String? targetTense;

  /// Secondary clause or sentence for comparative analysis.
  final String? secondarySentence;

  /// First dependent or independent clause in connector exercises.
  final String? firstClause;

  /// Second clause to be linked in connector exercises.
  final String? secondClause;

  /// Target conjunction or linking phrase to use.
  final String? connectorToUse;

  /// Cloze sentence template with an insertion blank.
  final String? sentenceWithBlank;

  /// Target article ('a', 'an', 'the', or null) to insert.
  final String? articleToInsert;

  /// Reading passage hosting grammatical questions.
  final String? passage;

  /// Passive voice representation of the trial sentence.
  final String? passiveSentence;

  /// Active voice representation of the trial sentence.
  final String? activeSentence;

  /// Name of the grammatical rule being taught.
  final String? grammarRule;

  /// Detailed pedagogical explanation of the grammar rule.
  final String? ruleExplanation;

  /// Substring identified as the syntactic error.
  final String? errorHighlight;

  /// Sentence syntactic structure classification.
  final String? structureType;

  /// Chronological position marker on a tense timeline (e.g. 'past', 'future').
  final String? timelinePosition;

  /// List of syntactic transformations applied to the sentence.
  final List<String>? transformations;

  /// Grammatical subject category (singular, plural, mass).
  final String? subjectType;

  /// Classification of connector (coordinating, subordinating, correlative).
  final String? connectorCategory;

  /// Active voice reference string.
  final String? activeVoice;

  /// Passive voice reference string.
  final String? passiveVoice;

  /// Syntactic question category (wh-question, yes/no, tag).
  final String? questionType;

  /// Pedagogical rule governing article usage.
  final String? articleRule;

  /// Modifier classification (adverbial, adjectival, dangling).
  final String? modifierType;

  /// Semantic meaning conveyed by the modal verb (ability, obligation).
  final String? modalMeaning;

  /// Prepositional domain category (time, place, direction).
  final String? prepositionCategory;

  /// Text fragment highlighting the pronoun's antecedent referent.
  final String? referentHighlight;

  /// Punctuation rule being applied (comma splice, colon, apostrophe).
  final String? punctuationRule;

  /// Clause classification (relative, adverbial, noun).
  final String? clauseType;

  /// Conditional structure category (zero, first, second, third, mixed).
  final String? conditionalType;

  /// Rhetorical purpose of the conjunction.
  final String? conjunctionPurpose;

  /// List of word changes between direct and reported speech.
  final List<String>? changesList;

  /// Creates a [GrammarQuest] entity with comprehensive syntactic properties.
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
    this.missingWord,
    this.incorrectPart,
    this.correctedPart,
    this.shuffledWords,
    this.correctOrder,
    super.explanation,
    this.prompt,
    super.textToSpeak,
    super.visualConfig,
    this.subject,
    this.verb,
    this.word,
    this.targetTense,
    this.secondarySentence,
    this.firstClause,
    this.secondClause,
    this.connectorToUse,
    this.sentenceWithBlank,
    this.articleToInsert,
    this.passage,
    this.passiveSentence,
    this.activeSentence,
    this.grammarRule,
    this.ruleExplanation,
    this.errorHighlight,
    this.structureType,
    this.timelinePosition,
    this.transformations,
    this.subjectType,
    this.connectorCategory,
    this.activeVoice,
    this.passiveVoice,
    this.questionType,
    this.articleRule,
    this.modifierType,
    this.modalMeaning,
    this.prepositionCategory,
    this.referentHighlight,
    this.punctuationRule,
    this.clauseType,
    this.conditionalType,
    this.conjunctionPurpose,
    this.changesList,
    super.targetWord,
    super.sentence,
    super.question,
  });

  /// Resolves the primary question text from passage, sentence, blank, or prompt fields.
  @override
  String? get question =>
      passage ?? sentence ?? sentenceWithBlank ?? passiveSentence ?? prompt;

  /// Resolves the canonical correct sentence representation.
  String? get correctSentence => correctAnswer ?? activeSentence ?? missingWord;

  @override
  List<Object?> get props => [
    ...super.props,
    missingWord,
    incorrectPart,
    correctedPart,
    shuffledWords,
    correctOrder,
    prompt,
    subject,
    verb,
    word,
    targetTense,
    secondarySentence,
    firstClause,
    secondClause,
    connectorToUse,
    sentenceWithBlank,
    articleToInsert,
    passage,
    passiveSentence,
    activeSentence,
    grammarRule,
    ruleExplanation,
    errorHighlight,
    structureType,
    timelinePosition,
  ];
}
