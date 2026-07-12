import 'package:vowl/core/domain/entities/game_quest.dart';

class EliteMasteryQuest extends GameQuest {
  final List<String>? sentences;
  final List<int>? correctOrder;
  final String? idiom;
  final String? word;
  final double? speedMultiplier;
  final String? audioUrl;
  final String? text;
  final String? shadowingFocus;
  final String? usageContext;
  final String? spellingRule;
  final String? sequenceLogic;


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
    this.audioUrl,
    this.text,
    this.shadowingFocus,
    this.usageContext,
    this.spellingRule,
    this.sequenceLogic,
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
    String? audioUrl,
    String? text,
    String? explanation,
    String? shadowingFocus,
    String? usageContext,
    String? spellingRule,
    String? sequenceLogic,
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
      audioUrl: audioUrl ?? this.audioUrl,
      text: text ?? this.text,
      explanation: explanation ?? this.explanation,
      shadowingFocus: shadowingFocus ?? this.shadowingFocus,
      usageContext: usageContext ?? this.usageContext,
      spellingRule: spellingRule ?? this.spellingRule,
      sequenceLogic: sequenceLogic ?? this.sequenceLogic,
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
    audioUrl,
    text,
    explanation,
    shadowingFocus,
    usageContext,
    spellingRule,
    sequenceLogic,
  ];
}
