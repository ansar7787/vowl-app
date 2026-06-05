import 'package:vowl/core/domain/entities/game_quest.dart';

class EliteMasteryQuest extends GameQuest {
  final List<String>? sentences;
  final List<int>? correctOrder;
  final String? idiom;
  final String? word;
  final double? speedMultiplier;
  final String? audioUrl;
  final String? text;

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
    this.sentences,
    this.correctOrder,
    this.idiom,
    this.word,
    this.speedMultiplier,
    this.audioUrl,
    this.text,
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
    List<String>? sentences,
    List<int>? correctOrder,
    String? idiom,
    String? word,
    double? speedMultiplier,
    String? audioUrl,
    String? text,
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
      sentences: sentences ?? this.sentences,
      correctOrder: correctOrder ?? this.correctOrder,
      idiom: idiom ?? this.idiom,
      word: word ?? this.word,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      audioUrl: audioUrl ?? this.audioUrl,
      text: text ?? this.text,
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
      ];
}
