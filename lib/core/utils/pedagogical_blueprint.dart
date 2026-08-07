import 'package:vowl/core/domain/entities/game_quest.dart';

class PedagogicalBlueprint {
  final List<String> radarAxes;
  final List<GameSubtype> tier1;
  final List<GameSubtype> tier2;
  final List<GameSubtype> tier3;
  final String tier1Label;
  final String tier2Label;
  final String tier3Label;

  const PedagogicalBlueprint({
    required this.radarAxes,
    required this.tier1,
    required this.tier2,
    required this.tier3,
    required this.tier1Label,
    required this.tier2Label,
    required this.tier3Label,
  });
}

class PedagogicalBlueprintMap {
  static const Map<String, PedagogicalBlueprint> blueprints = {
    'grammar': PedagogicalBlueprint(
      radarAxes: ['Syntax', 'Mechanics', 'Logic', 'Application'],
      tier1: [
        GameSubtype.partsOfSpeech,
        GameSubtype.grammarQuest,
        GameSubtype.subjectVerbAgreement,
        GameSubtype.articleInsertion,
        GameSubtype.prepositionChoice,
      ],
      tier2: [
        GameSubtype.tenseMastery,
        GameSubtype.wordReorder,
        GameSubtype.sentenceCorrection,
        GameSubtype.pronounResolution,
        GameSubtype.punctuationMastery,
        GameSubtype.questionFormatter,
      ],
      tier3: [
        GameSubtype.relativeClauses,
        GameSubtype.conditionals,
        GameSubtype.conjunctions,
        GameSubtype.clauseConnector,
        GameSubtype.voiceSwap,
        GameSubtype.modifierPlacement,
        GameSubtype.modalsSelection,
        GameSubtype.directIndirectSpeech,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: STRUCTURE',
      tier3Label: 'TIER 3: COMPLEX',
    ),
    'vocabulary': PedagogicalBlueprint(
      radarAxes: ['Definition', 'Context', 'Structure', 'Elite Usage'],
      tier1: [
        GameSubtype.flashcards,
        GameSubtype.synonymSearch,
        GameSubtype.antonymSearch,
        GameSubtype.topicVocab,
      ],
      tier2: [
        GameSubtype.contextClues,
        GameSubtype.contextualUsage,
        GameSubtype.wordFormation,
        GameSubtype.prefixSuffix,
      ],
      tier3: [
        GameSubtype.idioms,
        GameSubtype.phrasalVerbs,
        GameSubtype.collocations,
        GameSubtype.academicWord,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: APPLICATION',
      tier3Label: 'TIER 3: ELITE',
    ),
    'speaking': PedagogicalBlueprint(
      radarAxes: ['Recall', 'Pronunciation', 'Context', 'Fluency'],
      tier1: [
        GameSubtype.repeatSentence,
        GameSubtype.speakMissingWord,
        GameSubtype.speakSynonym,
        GameSubtype.speakOpposite,
      ],
      tier2: [
        GameSubtype.yesNoSpeaking,
        GameSubtype.dailyExpression,
        GameSubtype.pronunciationFocus,
      ],
      tier3: [
        GameSubtype.situationSpeaking,
        GameSubtype.sceneDescriptionSpeaking,
        GameSubtype.dialogueRoleplay,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: APPLICATION',
      tier3Label: 'TIER 3: FLUENCY',
    ),
    'listening': PedagogicalBlueprint(
      radarAxes: ['Comprehension', 'Detail', 'Speed', 'Inference'],
      tier1: [
        GameSubtype.soundImageMatch,
        GameSubtype.ambientId,
        GameSubtype.emotionRecognition,
      ],
      tier2: [
        GameSubtype.audioFillBlanks,
        GameSubtype.audioTrueFalse,
        GameSubtype.detailSpotlight,
      ],
      tier3: [
        GameSubtype.audioMultipleChoice,
        GameSubtype.audioSentenceOrder,
        GameSubtype.fastSpeechDecoder,
        GameSubtype.listeningInference,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: COMPREHENSION',
      tier3Label: 'TIER 3: ANALYSIS',
    ),
    'reading': PedagogicalBlueprint(
      radarAxes: ['Speed', 'Comprehension', 'Logic', 'Inference'],
      tier1: [
        GameSubtype.readAndMatch,
        GameSubtype.findWordMeaning,
        GameSubtype.guessTitle,
        GameSubtype.skimmingScanning,
      ],
      tier2: [
        GameSubtype.readAndAnswer,
        GameSubtype.trueFalseReading,
        GameSubtype.paragraphSummary,
        GameSubtype.clozeTest,
      ],
      tier3: [
        GameSubtype.sentenceOrderReading,
        GameSubtype.readingInference,
        GameSubtype.readingConclusion,
        GameSubtype.readingSpeedCheck,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: COMPREHENSION',
      tier3Label: 'TIER 3: ANALYSIS',
    ),
    'writing': PedagogicalBlueprint(
      radarAxes: ['Syntax', 'Expression', 'Correction', 'Structure'],
      tier1: [
        GameSubtype.sentenceBuilder,
        GameSubtype.completeSentence,
        GameSubtype.fixTheSentence,
        GameSubtype.correctionWriting,
      ],
      tier2: [
        GameSubtype.shortAnswerWriting,
        GameSubtype.dailyJournal,
        GameSubtype.describeSituationWriting,
      ],
      tier3: [
        GameSubtype.writingEmail,
        GameSubtype.summarizeStoryWriting,
        GameSubtype.opinionWriting,
        GameSubtype.essayDrafting,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: EXPRESSION',
      tier3Label: 'TIER 3: STRUCTURE',
    ),
    'roleplay': PedagogicalBlueprint(
      radarAxes: ['Social', 'Professional', 'Service', 'Crisis'],
      tier1: [
        GameSubtype.socialSpark,
        GameSubtype.branchingDialogue,
        GameSubtype.situationalResponse,
      ],
      tier2: [
        GameSubtype.travelDesk,
        GameSubtype.gourmetOrder,
        GameSubtype.medicalConsult,
      ],
      tier3: [
        GameSubtype.jobInterview,
        GameSubtype.elevatorPitch,
        GameSubtype.conflictResolver,
        GameSubtype.emergencyHub,
      ],
      tier1Label: 'TIER 1: SOCIAL',
      tier2Label: 'TIER 2: SERVICE',
      tier3Label: 'TIER 3: PROFESSIONAL',
    ),
    'accent': PedagogicalBlueprint(
      radarAxes: ['Pronunciation', 'Rhythm', 'Flow', 'Elite'],
      tier1: [
        GameSubtype.vowelDistinction,
        GameSubtype.consonantClarity,
        GameSubtype.minimalPairs,
      ],
      tier2: [
        GameSubtype.syllableStress,
        GameSubtype.pitchModulation,
        GameSubtype.speedVariance,
      ],
      tier3: [
        GameSubtype.wordLinking,
        GameSubtype.connectedSpeech,
        GameSubtype.intonationMimic,
        GameSubtype.pitchPatternMatch,
      ],
      tier1Label: 'TIER 1: FOUNDATIONS',
      tier2Label: 'TIER 2: RHYTHM',
      tier3Label: 'TIER 3: FLOW',
    ),
    'elitemastery': PedagogicalBlueprint(
      radarAxes: ['Speed', 'Accuracy', 'Memory', 'Synthesis'],
      tier1: [GameSubtype.speedSpelling],
      tier2: [GameSubtype.idiomMatch],
      tier3: [GameSubtype.storyBuilder, GameSubtype.accentShadowing],
      tier1Label: 'TIER 1: SPEED',
      tier2Label: 'TIER 2: ACCURACY',
      tier3Label: 'TIER 3: SYNTHESIS',
    ),
  };

  static PedagogicalBlueprint? getBlueprint(String categoryId) {
    return blueprints[categoryId.toLowerCase().replaceAll(' ', '')];
  }
}
