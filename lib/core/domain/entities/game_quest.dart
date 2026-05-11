import 'package:equatable/equatable.dart';

enum InteractionType {
  speech,
  choice,
  writing,
  sequence,
  match,
  speaking,
  typing,
  reorder,
  trueFalse,
  text,
  spell,
  voice,
  selection,
  dialogue,
  slider,
  rating,
  mapping,
  bubbles,
  flip,
  lens,
  mirror,
  rub,
  paint,
  sort,
  lab,
  tree,
  slot,
  chain,
  scroll,
  verdict,
  condenser,
  search,
  journal,
  digest,
  audit,
  draft,
  blueprint,
  echo,
  verbalizer,
  narrator,
  pivot,
  clarity,
  radar,
  probe,
  pulse,
  anchor,
  mimic,
  shadow,
  stress,
  linking,
}

enum GameSubtype {
  // 1. Speaking
  repeatSentence,
  speakMissingWord,
  situationSpeaking,
  sceneDescriptionSpeaking,
  yesNoSpeaking,
  speakSynonym,
  dialogueRoleplay,
  pronunciationFocus,
  speakOpposite,
  dailyExpression,
  // 2. Listening
  audioFillBlanks,
  audioMultipleChoice,
  audioSentenceOrder,
  audioTrueFalse,
  soundImageMatch,
  fastSpeechDecoder,
  emotionRecognition,
  detailSpotlight,
  listeningInference,
  ambientId,
  // 3. Reading
  readAndAnswer,
  findWordMeaning,
  trueFalseReading,
  sentenceOrderReading,
  readingSpeedCheck,
  guessTitle,
  readAndMatch,
  paragraphSummary,
  readingInference,
  readingConclusion,
  clozeTest,
  skimmingScanning,
  // 4. Writing
  sentenceBuilder,
  completeSentence,
  describeSituationWriting,
  fixTheSentence,
  shortAnswerWriting,
  opinionWriting,
  dailyJournal,
  summarizeStoryWriting,
  writingEmail,
  correctionWriting,
  essayDrafting,
  // 5. Grammar
  grammarQuest,
  sentenceCorrection,
  wordReorder,
  tenseMastery,
  partsOfSpeech,
  subjectVerbAgreement,
  clauseConnector,
  voiceSwap,
  questionFormatter,
  articleInsertion,
  modifierPlacement,
  modalsSelection,
  prepositionChoice,
  pronounResolution,
  punctuationMastery,
  relativeClauses,
  conditionals,
  conjunctions,
  directIndirectSpeech,
  // 6. Vocabulary
  flashcards,
  synonymSearch,
  antonymSearch,
  contextClues,
  phrasalVerbs,
  idioms,
  academicWord,
  topicVocab,
  wordFormation,
  prefixSuffix,
  collocations,
  contextualUsage,
  // 7. Accent
  minimalPairs,
  intonationMimic,
  syllableStress,
  wordLinking,
  shadowingChallenge,
  vowelDistinction,
  consonantClarity,
  pitchPatternMatch,
  speedVariance,
  dialectDrill,
  connectedSpeech,
  pitchModulation,
  // 8. Roleplay
  branchingDialogue,
  situationalResponse,
  jobInterview,
  medicalConsult,
  gourmetOrder,
  travelDesk,
  conflictResolver,
  elevatorPitch,
  socialSpark,
  emergencyHub,
  // 9. Elite Mastery
  storyBuilder,
  idiomMatch,
  speedSpelling,
  accentShadowing,
}

enum QuestType {
  speaking,
  listening,
  reading,
  writing,
  grammar,
  vocabulary,
  accent,
  roleplay,
  eliteMastery,
}

extension GameSubtypeX on GameSubtype {
  QuestType get category {
    if (index <= GameSubtype.dailyExpression.index) return QuestType.speaking;
    if (index <= GameSubtype.ambientId.index) return QuestType.listening;
    if (index <= GameSubtype.skimmingScanning.index) return QuestType.reading;
    if (index <= GameSubtype.essayDrafting.index) return QuestType.writing;
    if (index <= GameSubtype.directIndirectSpeech.index) return QuestType.grammar;
    if (index <= GameSubtype.contextualUsage.index) return QuestType.vocabulary;
    if (index <= GameSubtype.pitchModulation.index) return QuestType.accent;
    if (index <= GameSubtype.emergencyHub.index) return QuestType.roleplay;
    return QuestType.eliteMastery;
  }

  bool get isLegacy => false;
}

extension QuestTypeX on QuestType {
  List<GameSubtype> get subtypes {
    switch (this) {
      case QuestType.speaking:
        return GameSubtype.values.sublist(
          GameSubtype.repeatSentence.index,
          GameSubtype.dailyExpression.index + 1,
        );
      case QuestType.listening:
        return GameSubtype.values.sublist(
          GameSubtype.audioFillBlanks.index,
          GameSubtype.ambientId.index + 1,
        );
      case QuestType.reading:
        return GameSubtype.values.sublist(
          GameSubtype.readAndAnswer.index,
          GameSubtype.skimmingScanning.index + 1,
        );
      case QuestType.writing:
        return GameSubtype.values.sublist(
          GameSubtype.sentenceBuilder.index,
          GameSubtype.essayDrafting.index + 1,
        );
      case QuestType.grammar:
        return GameSubtype.values.sublist(
          GameSubtype.grammarQuest.index,
          GameSubtype.directIndirectSpeech.index + 1,
        );
      case QuestType.vocabulary:
        return GameSubtype.values.sublist(
          GameSubtype.flashcards.index,
          GameSubtype.contextualUsage.index + 1,
        );
      case QuestType.accent:
        return GameSubtype.values.sublist(
          GameSubtype.minimalPairs.index,
          GameSubtype.pitchModulation.index + 1,
        );
      case QuestType.roleplay:
        return GameSubtype.values.sublist(
          GameSubtype.branchingDialogue.index,
          GameSubtype.emergencyHub.index + 1,
        );
      case QuestType.eliteMastery:
        return GameSubtype.values.sublist(
          GameSubtype.storyBuilder.index,
          GameSubtype.accentShadowing.index + 1,
        );
    }
  }

  String get name {
    switch (this) {
      case QuestType.speaking:
        return 'speaking';
      case QuestType.listening:
        return 'listening';
      case QuestType.reading:
        return 'reading';
      case QuestType.writing:
        return 'writing';
      case QuestType.grammar:
        return 'grammar';
      case QuestType.vocabulary:
        return 'vocabulary';
      case QuestType.accent:
        return 'accent';
      case QuestType.roleplay:
        return 'roleplay';
      case QuestType.eliteMastery:
        return 'elitemastery';
    }
  }
}

/// Visual configuration for quest UI theming.
/// Maps to the `visual_config` JSON object in curriculum files.
class VisualConfig extends Equatable {
  final String painterType;
  final String primaryColor;
  final double pulseIntensity;
  final String shaderEffect;

  const VisualConfig({
    this.painterType = 'DataLogSync',
    this.primaryColor = '0xFF03A9F4',
    this.pulseIntensity = 0.5,
    this.shaderEffect = 'glow_shimmer',
  });

  /// Parse from JSON map.
  factory VisualConfig.fromJson(Map<String, dynamic> json) {
    return VisualConfig(
      painterType: json['painter_type'] as String? ?? 'DataLogSync',
      primaryColor: json['primary_color'] as String? ?? '0xFF03A9F4',
      pulseIntensity: (json['pulse_intensity'] as num?)?.toDouble() ?? 0.5,
      shaderEffect: json['shader_effect'] as String? ?? 'glow_shimmer',
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
    'painter_type': painterType,
    'primary_color': primaryColor,
    'pulse_intensity': pulseIntensity,
    'shader_effect': shaderEffect,
  };

  @override
  List<Object?> get props => [painterType, primaryColor, pulseIntensity, shaderEffect];
}

class GameQuest extends Equatable {
  final String id;
  final QuestType? type;
  final String instruction;
  final int difficulty;
  final GameSubtype? subtype;
  final InteractionType interactionType;
  final int xpReward;
  final int coinReward;
  final int livesAllowed;
  final List<String>? options;
  final int? correctAnswerIndex;
  final String? correctAnswer;
  final String? hint;
  final String? textToSpeak;
  final VisualConfig? visualConfig;

  const GameQuest({
    required this.id,
    this.type,
    required this.instruction,
    required this.difficulty,
    this.subtype,
    this.interactionType = InteractionType.choice,
    this.xpReward = 10,
    this.coinReward = 10,
    this.livesAllowed = 3,
    this.options,
    this.correctAnswerIndex,
    this.correctAnswer,
    this.hint,
    this.textToSpeak,
    this.visualConfig,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    instruction,
    difficulty,
    subtype,
    interactionType,
    xpReward,
    coinReward,
    livesAllowed,
    options,
    correctAnswerIndex,
    correctAnswer,
    hint,
    textToSpeak,
    visualConfig,
  ];
}
