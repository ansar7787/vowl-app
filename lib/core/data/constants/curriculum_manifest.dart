// GENERATED FILE — DO NOT EDIT
// Run: dart run scripts/generate_curriculum_manifest.dart
//
// Generated: 2026-10-06T09:52:16.094088
// Total game types: 100 main games

import 'package:flutter/foundation.dart';

/// Build-time generated manifest of curriculum level counts.
///
/// Each entry maps a game type to its total number of available levels,
/// derived from the highest batch file found in `assets/curriculum/`.
///
/// This eliminates runtime asset manifest scanning entirely.
@immutable
abstract class CurriculumManifest {
  const CurriculumManifest._();

  /// Default level count when a game type is not in the manifest.
  /// New games added after the last code-gen run will fall back to this.
  static const int defaultLevelCount = 10;

  /// Total number of levels for each registered game type.
  static const Map<String, int> levelCounts = {
    // ── Main Games (100) ──
    'academicWord': 200,
    'accentShadowing': 200,
    'ambientId': 200,
    'antonymSearch': 200,
    'articleInsertion': 200,
    'audioFillBlanks': 200,
    'audioMultipleChoice': 200,
    'audioSentenceOrder': 200,
    'audioTrueFalse': 200,
    'branchingDialogue': 200,
    'clauseConnector': 200,
    'clozeTest': 200,
    'collocations': 200,
    'completeSentence': 200,
    'conditionals': 200,
    'conflictResolver': 200,
    'conjunctions': 200,
    'connectedSpeech': 200,
    'consonantClarity': 200,
    'contextClues': 200,
    'contextualUsage': 200,
    'correctionWriting': 200,
    'dailyExpression': 200,
    'dailyJournal': 200,
    'describeSituationWriting': 200,
    'detailSpotlight': 200,
    'dialectDrill': 200,
    'dialogueRoleplay': 200,
    'directIndirectSpeech': 200,
    'elevatorPitch': 200,
    'emergencyHub': 200,
    'emotionRecognition': 200,
    'essayDrafting': 200,
    'fastSpeechDecoder': 200,
    'findWordMeaning': 200,
    'fixTheSentence': 200,
    'flashcards': 200,
    'gourmetOrder': 200,
    'grammarQuest': 200,
    'guessTitle': 200,
    'idiomMatch': 200,
    'idioms': 200,
    'intonationMimic': 200,
    'jobInterview': 200,
    'listeningInference': 200,
    'medicalConsult': 200,
    'minimalPairs': 200,
    'modalsSelection': 200,
    'modifierPlacement': 200,
    'opinionWriting': 200,
    'paragraphSummary': 200,
    'partsOfSpeech': 200,
    'phrasalVerbs': 200,
    'pitchModulation': 200,
    'pitchPatternMatch': 200,
    'prefixSuffix': 200,
    'prepositionChoice': 200,
    'pronounResolution': 200,
    'pronunciationFocus': 200,
    'punctuationMastery': 200,
    'questionFormatter': 200,
    'readAndAnswer': 200,
    'readAndMatch': 200,
    'readingConclusion': 200,
    'readingInference': 200,
    'readingSpeedCheck': 200,
    'relativeClauses': 200,
    'repeatSentence': 200,
    'sceneDescriptionSpeaking': 200,
    'sentenceBuilder': 200,
    'sentenceCorrection': 200,
    'sentenceOrderReading': 200,
    'shadowingChallenge': 200,
    'shortAnswerWriting': 200,
    'situationSpeaking': 200,
    'situationalResponse': 200,
    'skimmingScanning': 200,
    'socialSpark': 200,
    'soundImageMatch': 200,
    'speakMissingWord': 200,
    'speakOpposite': 200,
    'speakSynonym': 200,
    'speedSpelling': 200,
    'speedVariance': 200,
    'storyBuilder': 200,
    'subjectVerbAgreement': 200,
    'summarizeStoryWriting': 200,
    'syllableStress': 200,
    'synonymSearch': 200,
    'tenseMastery': 200,
    'topicVocab': 200,
    'travelDesk': 200,
    'trueFalseReading': 200,
    'voiceSwap': 200,
    'vowelDistinction': 200,
    'wordFormation': 200,
    'wordLinking': 200,
    'wordReorder': 200,
    'writingEmail': 200,
    'yesNoSpeaking': 200,
  };

  /// Returns the level count for [gameType], falling back to [defaultLevelCount].
  static int getLevels(String gameType) =>
      levelCounts[gameType] ?? defaultLevelCount;
}
