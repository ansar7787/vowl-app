import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity encapsulating reading comprehension quests and passage data.
class ReadingQuest extends GameQuest {
  /// The primary narrative or informative passage for reading.
  final String? passage;

  /// Specific highlighted term targeted for vocabulary analysis.
  final String? highlightedWord;

  /// Contextual statement evaluated in comprehension exercises.
  final String? statement;

  /// Unordered sentences for sequence reconstruction quests.
  final List<String>? shuffledSentences;

  /// Zero-based indices indicating correct chronological sentence order.
  final List<int>? correctOrder;

  /// Key-value association pairs for matching activities.
  final List<Map<String, String>>? pairs;

  /// Phonetic or pronunciation guidance hint.
  final String? phoneticHint;

  /// Contextual scenario or instruction prompt.
  final String? prompt;

  /// Target keywords pertinent to the passage.
  final List<String>? keywords;

  /// Maximum allowed duration in seconds for speed-reading challenges.
  final int? timeLimit;

  /// Target scanning token or answer target.
  final String? targetItem;

  /// Total word count of the reading passage.
  final int? passageWordCount;

  /// Specific word excerpted with immediate context.
  final String? wordInContext;

  /// Supporting quote or citation line verifying the correct answer.
  final String? evidenceLine;

  /// List of discourse markers or transition words highlighted.
  final List<String>? transitionWords;

  /// Target words-per-minute threshold for fluency exercises.
  final int? wpmTarget;

  /// Rationale explaining the appropriateness of a chosen title.
  final String? whyThisTitle;

  /// Central subject or main idea of the paragraph.
  final String? paragraphTopic;

  /// Salient takeaway points summarizing the passage.
  final List<String>? keyPoints;

  /// Contextual clue words pointing to inferred meaning.
  final List<String>? clueWords;

  /// Sequential deductive steps connecting premises to conclusions.
  final List<String>? logicChain;

  /// Syntactic or semantic grouping category for the target word.
  final String? wordCategory;

  /// Specific factual data point to locate during skimming.
  final String? targetInfo;

  /// Creates a [ReadingQuest] entity.
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
    super.question,
    this.highlightedWord,
    this.statement,
    this.shuffledSentences,
    this.correctOrder,
    this.pairs,
    this.phoneticHint,
    super.targetWord,
    super.explanation,
    super.textToSpeak,
    super.visualConfig,
    this.prompt,
    this.keywords,
    this.timeLimit,
    this.targetItem,
    this.passageWordCount,
    this.wordInContext,
    this.evidenceLine,
    this.transitionWords,
    this.wpmTarget,
    this.whyThisTitle,
    this.paragraphTopic,
    this.keyPoints,
    this.clueWords,
    this.logicChain,
    this.wordCategory,
    this.targetInfo,
  });

  String? get word => targetWord ?? highlightedWord;

  @override
  List<Object?> get props => [
    ...super.props,
    passage,
    highlightedWord,
    statement,
    shuffledSentences,
    correctOrder,
    pairs,
    phoneticHint,
    prompt,
    keywords,
    timeLimit,
    targetItem,
    passageWordCount,
    wordInContext,
    evidenceLine,
    transitionWords,
    wpmTarget,
    whyThisTitle,
    paragraphTopic,
    keyPoints,
    clueWords,
    logicChain,
    wordCategory,
    targetInfo,
  ];
}
