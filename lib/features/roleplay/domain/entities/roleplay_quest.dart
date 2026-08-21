import 'package:equatable/equatable.dart';
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
  final List<String>? shuffledWords;
  final List<String>? consequencePreviews;
  final List<int>? consequenceScores;
  final String? culturalNote;
  final int? formalityScore;
  final List<String>? interviewerReaction;
  final List<String>? medicalVocab;
  final List<String>? menuItems;
  final List<String>? menuPrices;
  final String? travelDocuments;
  final int? escalationLevel;
  final int? timeLimit;
  final String? socialContext;
  final int? urgencyLevel;

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
    super.explanation,
    this.shuffledWords,
    this.consequencePreviews,
    this.consequenceScores,
    this.culturalNote,
    this.formalityScore,
    this.interviewerReaction,
    this.medicalVocab,
    this.menuItems,
    this.menuPrices,
    this.travelDocuments,
    this.escalationLevel,
    this.timeLimit,
    this.socialContext,
    this.urgencyLevel,
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
    shuffledWords,
    consequencePreviews,
    consequenceScores,
    culturalNote,
    formalityScore,
    interviewerReaction,
    medicalVocab,
    menuItems,
    menuPrices,
    travelDocuments,
    escalationLevel,
    timeLimit,
    socialContext,
    urgencyLevel,
  ];
}

class DialogueNode extends Equatable {
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

  @override
  List<Object?> get props => [id, speaker, text, choices, end, emotion];
}

class DialogueChoice extends Equatable {
  final String text;
  final String? next;
  final int? score;

  const DialogueChoice({required this.text, this.next, this.score});

  @override
  List<Object?> get props => [text, next, score];
}
