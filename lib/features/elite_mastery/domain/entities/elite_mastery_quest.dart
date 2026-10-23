import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing an advanced challenge in the Elite Mastery arena.
class EliteMasteryQuest extends GameQuest {
  /// Ordered list of narrative sentences used in story builder quests.
  final List<String>? sentences;

  /// Target permutation indices representing the correct sequence order.
  final List<int>? correctOrder;

  /// Target phrase or idiom for idiom matching exercises.
  final String? idiom;

  /// Word or lexical token to be decoded in speed spelling.
  final String? word;

  /// Playback or timer speed multiplier factor.
  final double? speedMultiplier;

  /// Passage or speech excerpt for accent shadowing exercises.
  final String? text;

  /// Phonetic emphasis or focus element for shadowing.
  final String? shadowingFocus;

  /// Example conversational context showing real-world usage.
  final String? usageContext;

  /// Orthographic rule or pedagogical tip for spelling exercises.
  final String? spellingRule;

  /// Explanatory rationale behind the correct sentence sequence.
  final String? sequenceLogic;

  /// Narrative arc role (e.g., exposition, climax, resolution).
  final String? plotStructure;

  /// Historical etymology or origin story of the idiom.
  final String? idiomOrigin;

  /// Metaphorical imagery illustrating the expression.
  final String? visualMetaphor;

  /// Qualitative challenge level (e.g. Master, Grandmaster).
  final String? difficultyTier;

  /// Dialect or accent variant targeted in the exercise.
  final String? targetAccent;

  /// Creates an [EliteMasteryQuest] domain entity.
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
    // FIX: `question` is a GameQuest-level field (used directly by
    // IdiomMatchScreen as `quest.question`) that was never forwarded here,
    // so it was always null regardless of what the curriculum JSON
    // contained for it. See EliteMasteryQuestModel.fromJson for the other
    // half of this fix.
    super.question,
    super.explanation,
    this.sentences,
    this.correctOrder,
    this.idiom,
    this.word,
    this.speedMultiplier,
    this.text,
    this.shadowingFocus,
    this.usageContext,
    this.spellingRule,
    this.sequenceLogic,
    this.plotStructure,
    this.idiomOrigin,
    this.visualMetaphor,
    this.difficultyTier,
    this.targetAccent,
  });

  EliteMasteryQuest copyWith({
    String? id,
    QuestType? type,
    String? instruction,
    int? difficulty,
    GameSubtype? subtype,
    InteractionType? interactionType,
    int? xpReward,
    int? coinReward,
    int? livesAllowed,
    List<String>? options,
    int? correctAnswerIndex,
    String? correctAnswer,
    String? hint,
    String? textToSpeak,
    VisualConfig? visualConfig,
    String? question,
    List<String>? sentences,
    List<int>? correctOrder,
    String? idiom,
    String? word,
    double? speedMultiplier,
    String? text,
    String? explanation,
    String? shadowingFocus,
    String? usageContext,
    String? spellingRule,
    String? sequenceLogic,
    String? plotStructure,
    String? idiomOrigin,
    String? visualMetaphor,
    String? difficultyTier,
    String? targetAccent,
  }) {
    return EliteMasteryQuest(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      difficulty: difficulty ?? this.difficulty,
      subtype: subtype ?? this.subtype,
      interactionType: interactionType ?? this.interactionType,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      livesAllowed: livesAllowed ?? this.livesAllowed,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      hint: hint ?? this.hint,
      textToSpeak: textToSpeak ?? this.textToSpeak,
      visualConfig: visualConfig ?? this.visualConfig,
      question: question ?? this.question,
      sentences: sentences ?? this.sentences,
      correctOrder: correctOrder ?? this.correctOrder,
      idiom: idiom ?? this.idiom,
      word: word ?? this.word,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      text: text ?? this.text,
      explanation: explanation ?? this.explanation,
      shadowingFocus: shadowingFocus ?? this.shadowingFocus,
      usageContext: usageContext ?? this.usageContext,
      spellingRule: spellingRule ?? this.spellingRule,
      sequenceLogic: sequenceLogic ?? this.sequenceLogic,
      plotStructure: plotStructure ?? this.plotStructure,
      idiomOrigin: idiomOrigin ?? this.idiomOrigin,
      visualMetaphor: visualMetaphor ?? this.visualMetaphor,
      difficultyTier: difficultyTier ?? this.difficultyTier,
      targetAccent: targetAccent ?? this.targetAccent,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    sentences,
    correctOrder,
    idiom,
    word,
    speedMultiplier,
    text,
    explanation,
    shadowingFocus,
    usageContext,
    spellingRule,
    sequenceLogic,
    plotStructure,
    idiomOrigin,
    visualMetaphor,
    difficultyTier,
    targetAccent,
  ];
}
