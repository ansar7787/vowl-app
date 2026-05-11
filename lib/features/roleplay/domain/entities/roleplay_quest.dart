import 'package:vowl/core/domain/entities/game_quest.dart';

class RoleplayQuest extends GameQuest {
  final String? scene;
  final String? persona;
  final String? prompt;
  final String? sampleAnswer;
  final Map<String, DialogueNode>? dialogues;
  final String? situation;
  final List<String>? keywords;
  final List<Map<String, String>>? conversationHistory;

  // Extra fields from various Roleplay games
  final String? lastLine;
  final String? dispatcherQuestion;
  final String? interviewerQuestion;
  final double? empathyScore;
  final int? professionalismRating;
  final List<String>? symptoms;
  final List<String>? itinerary;
  final String? explanation;
  final List<String>? shuffledWords;

  const RoleplayQuest({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.speech,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    this.scene,
    this.persona,
    this.prompt,
    this.sampleAnswer,
    super.textToSpeak,
    super.visualConfig,
    this.dialogues,
    this.situation,
    this.keywords,
    this.conversationHistory,
    this.lastLine,
    this.dispatcherQuestion,
    this.interviewerQuestion,
    this.empathyScore,
    this.professionalismRating,
    this.symptoms,
    this.itinerary,
    this.explanation,
    this.shuffledWords,
  });

  String? get roleName => persona;
  
  @override
  List<Object?> get props => [
    ...super.props,
    scene,
    persona,
    prompt,
    sampleAnswer,
    dialogues,
    situation,
    keywords,
    conversationHistory,
    lastLine,
    dispatcherQuestion,
    interviewerQuestion,
    empathyScore,
    professionalismRating,
    symptoms,
    itinerary,
    explanation,
    shuffledWords,
  ];
}

class DialogueNode {
  final String id;
  final String speaker;
  final String text;
  final List<DialogueChoice>? choices;
  final bool end;
  final String? emotion; // e.g., 'happy', 'worried', 'angry', 'thinking'

  const DialogueNode({
    required this.id,
    required this.speaker,
    required this.text,
    this.choices,
    this.end = false,
    this.emotion,
  });
}

class DialogueChoice {
  final String text;
  final String? next;
  final int? score;

  const DialogueChoice({required this.text, this.next, this.score});
}

