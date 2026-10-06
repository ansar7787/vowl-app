// GENERATED FILE — DO NOT EDIT
// Run: dart run scripts/generate_curriculum_manifest.dart
//
// Generated: 2026-10-06T09:52:16.094088
// Total game types: 125 (100 main + 25 kids)

import 'package:flutter/foundation.dart';

/// Build-time generated manifest of curriculum level counts.
///
/// Each entry maps a game type to its total number of available levels,
/// derived from the highest batch file found in `assets/curriculum/`.
///
/// **Main games** use their gameType as-is (e.g., `repeatSentence`).
/// **Kids games** are prefixed with `kids_` (e.g., `kids_alphabet`).
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

    // ── Kids Games (25) ──
    'kids_alphabet': 200,
    'kids_animals': 200,
    'kids_body_parts': 200,
    'kids_clothing': 200,
    'kids_colors': 200,
    'kids_day_night': 200,
    'kids_emotions': 200,
    'kids_family': 200,
    'kids_food': 200,
    'kids_fruits': 200,
    'kids_handwriting': 200,
    'kids_home': 200,
    'kids_nature': 200,
    'kids_numbers': 200,
    'kids_opposites': 200,
    'kids_phonics': 200,
    'kids_prepositions': 200,
    'kids_professions': 200,
    'kids_routine': 200,
    'kids_school': 200,
    'kids_shapes': 200,
    'kids_time': 200,
    'kids_transport': 200,
    'kids_verbs': 200,
    'kids_weather': 200,
  };

  /// Kids game level counts (without the `kids_` prefix).
  /// Use this when looking up kids games by their raw topic name.
  static const Map<String, int> kidsLevelCounts = {
    'alphabet': 200,
    'animals': 200,
    'body_parts': 200,
    'clothing': 200,
    'colors': 200,
    'day_night': 200,
    'emotions': 200,
    'family': 200,
    'food': 200,
    'fruits': 200,
    'handwriting': 200,
    'home': 200,
    'nature': 200,
    'numbers': 200,
    'opposites': 200,
    'phonics': 200,
    'prepositions': 200,
    'professions': 200,
    'routine': 200,
    'school': 200,
    'shapes': 200,
    'time': 200,
    'transport': 200,
    'verbs': 200,
    'weather': 200,
  };

  /// Returns the level count for [gameType], or [defaultLevelCount]
  /// if the game type was not present at build time.
  static int getLevels(String gameType) =>
      levelCounts[gameType] ?? defaultLevelCount;

  /// Returns the level count for a kids game by topic name.
  /// Accepts both `"alphabet"` and `"kids_alphabet"` forms.
  static int getKidsLevels(String topic) =>
      kidsLevelCounts[topic] ?? levelCounts['kids_$topic'] ?? defaultLevelCount;
}
