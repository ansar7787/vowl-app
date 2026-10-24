import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity encapsulating an interactive conversational roleplay quest.
class RoleplayQuest extends GameQuest {
  /// Contextual scenario description for the roleplay interaction.
  final String? scene;

  /// Name or character persona of the conversational partner.
  final String? persona;

  /// Specific conversation prompt or instruction.
  final String? prompt;

  /// Reference exemplar response.
  final String? sampleAnswer;

  /// Mapped dialogue nodes for branching conversational trees.
  final Map<String, DialogueNode>? dialogues;

  /// Narrative situation background.
  final String? situation;

  /// Target conversational vocabulary words.
  final List<String>? keywords;

  /// Prior dialogue exchanges providing conversation context.
  final List<Map<String, String>>? conversationHistory;

  /// The preceding line spoken by the conversational partner.
  final String? lastLine;

  /// Emergency dispatcher inquiry line.
  final String? dispatcherQuestion;

  /// Job interviewer prompt.
  final String? interviewerQuestion;

  /// Expected empathy rating benchmark.
  final double? empathyScore;

  /// Target professionalism evaluation metric.
  final int? professionalismRating;

  /// Medical patient complaint symptoms.
  final List<String>? symptoms;

  /// Travel destination and travel itinerary details.
  final List<String>? itinerary;

  /// Scrambled words for sentence formation within roleplay.
  final List<String>? shuffledWords;

  /// Consequence descriptions for choices.
  final List<String>? consequencePreviews;

  /// Numeric score impacts for conversation paths.
  final List<int>? consequenceScores;

  /// Sociolinguistic or cultural etiquette context.
  final String? culturalNote;

  /// Expected formality index of the exchange.
  final int? formalityScore;

  /// Reaction feedback lines from the interviewer.
  final List<String>? interviewerReaction;

  /// Medical terminology for consulting.
  final List<String>? medicalVocab;

  /// Restaurant dishes for gourmet ordering.
  final List<String>? menuItems;

  /// Price tags matching menu items.
  final List<String>? menuPrices;

  /// Visa or passport travel documents.
  final String? travelDocuments;

  /// Severity rating of the situation.
  final int? escalationLevel;

  /// Seconds allocated for rapid elevator pitches or emergencies.
  final int? timeLimit;

  /// Social setting and power dynamics.
  final String? socialContext;

  /// Urgency index for triage.
  final int? urgencyLevel;

  /// Creates a [RoleplayQuest] instance.
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

  /// The role or character persona name.
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

/// Node representing a single conversational step or turn within a branching dialogue.
class DialogueNode extends Equatable {
  /// Unique identifier of this dialogue node.
  final String id;

  /// The character persona speaking this line.
  final String speaker;

  /// The spoken line content.
  final String text;

  /// Available branching response choices.
  final List<DialogueChoice>? choices;

  /// Whether this node represents the end of the conversation.
  final bool end;

  /// Emotional tone or sentiment of the speaker.
  final String? emotion;

  /// Creates a [DialogueNode] instance.
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

/// Interactive user response option within a dialogue node.
class DialogueChoice extends Equatable {
  /// Text content of this response choice.
  final String text;

  /// Key of the target dialogue node navigated to upon selecting this choice.
  final String? next;

  /// Score modifier associated with choosing this response.
  final int? score;

  /// Creates a [DialogueChoice] instance.
  const DialogueChoice({required this.text, this.next, this.score});

  @override
  List<Object?> get props => [text, next, score];
}
