import 'package:vowl/core/domain/entities/game_quest.dart';

class ReadingQuest extends GameQuest {
  final String? passage;
  final String? highlightedWord;
  final String? statement;
  final List<String>? shuffledSentences;
  final List<int>? correctOrder;
  final List<Map<String, String>>? pairs;
  final String? phoneticHint;
  final String? prompt;
  final List<String>? keywords;
  final int? timeLimit;
  final String? targetItem;

  // D3 Fields
  final int? passageWordCount;
  final String? wordInContext;
  final String? evidenceLine;
  final List<String>? transitionWords;
  final int? wpmTarget;
  final String? whyThisTitle;
  final String? paragraphTopic;
  final List<String>? keyPoints;
  final List<String>? clueWords;
  final List<String>? logicChain;
  final String? wordCategory;
  final String? targetInfo;

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
