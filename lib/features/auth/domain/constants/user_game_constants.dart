/// Centralized constants for the Vowl game domain.
///
/// Extracted to a single source of truth, eliminating the critical duplication
/// of [kDefaultUnlockedLevels] previously copy-pasted verbatim across both
/// [UserEntity] and [UserModel] (100+ lines each).
///
/// All repository implementations and domain entities import from here.
abstract final class UserGameConstants {
  // ---------------------------------------------------------------------------
  // History & Collection Limits
  // ---------------------------------------------------------------------------

  /// Maximum number of entries retained in both [coinHistory] and [recentActivities].
  static const int kActivityHistoryLimit = 10;

  /// Maximum number of days retained in [dailyXpHistory].
  static const int kDailyXpHistoryLimit = 30;

  // ---------------------------------------------------------------------------
  // Category Stat Bounds
  // ---------------------------------------------------------------------------

  /// XP adjustment applied per correct/incorrect answer to [categoryStats].
  static const int kCategoryStatStep = 10;

  /// Starting [categoryStats] score for any new category entry.
  static const int kCategoryStatDefault = 50;

  /// Floor value for any category stat score.
  static const int kCategoryStatMin = 0;

  /// Ceiling value for any category stat score.
  static const int kCategoryStatMax = 100;

  // ---------------------------------------------------------------------------
  // XP Multipliers & Thresholds
  // ---------------------------------------------------------------------------

  /// XP per user level. Level = (totalExp / kXpPerLevel).floor() + 1.
  static const int kXpPerLevel = 100;

  /// Additional XP multiplier granted by a permanent XP boost (10%).
  static const double kPermanentXpBoostMultiplier = 1.1;

  /// XP multiplier granted when Double XP power-up is active (2×).
  static const double kDoubleXpMultiplier = 2.0;

  /// Fraction of base XP awarded when replaying an already-completed level.
  static const double kReplayXpFraction = 0.5;

  // ---------------------------------------------------------------------------
  // Daily Rewards
  // ---------------------------------------------------------------------------

  /// Flat coin reward for claiming the VIP daily gift.
  static const int kVipDailyGiftReward = 100;

  /// Base coin amount for the standard daily gift.
  static const int kDailyGiftBaseReward = 50;

  /// Coin increment applied per day-of-month cycle for the daily gift.
  static const int kDailyGiftCycleIncrement = 10;

  // ---------------------------------------------------------------------------
  // Kids Zone Defaults
  // ---------------------------------------------------------------------------

  /// Default furniture items unlocked for every new Kids Zone user.
  static const List<String> kDefaultKidsOwnedFurniture = [
    'default_bed',
    'default_window',
  ];

  /// Default equipped furniture mapping for every new Kids Zone user.
  static const Map<String, String> kDefaultKidsEquippedFurniture = {
    'bed': 'default_bed',
    'window': 'default_window',
  };

  // ---------------------------------------------------------------------------
  // Vowl Mascot Defaults
  // ---------------------------------------------------------------------------

  /// Default mascot collection every new user receives at registration.
  static const List<String> kDefaultVowlOwnedMascots = ['vowl_prime'];

  // ---------------------------------------------------------------------------
  // Kids Game Type Registry
  // ---------------------------------------------------------------------------

  /// The complete set of Kids Zone game type identifiers.
  ///
  /// Used by [GamificationRepositoryImpl.updateUserRewards] to route rewards
  /// into [kidsCoins] instead of the standard [coins] bucket.
  static const Set<String> kKidsGameTypes = {
    'alphabet',
    'numbers',
    'colors',
    'shapes',
    'animals',
    'fruits',
    'family',
    'school',
    'verbs',
    'routine',
    'emotions',
    'prepositions',
    'phonics',
    'day_night',
    'nature',
    'home_kids',
    'food_kids',
    'transport',
    'time',
    'opposites',
    'body_parts',
    'clothing',
  };

  // ---------------------------------------------------------------------------
  // Default Unlocked Levels
  // ---------------------------------------------------------------------------

  /// The full default unlocked-levels map assigned to every new user.
  ///
  /// Every game and category starts at level 1. Previously this was duplicated
  /// verbatim in both [UserEntity] and [UserModel]; it now lives here alone.
  static const Map<String, int> kDefaultUnlockedLevels = {
    // 1. Speaking (10 Games)
    'repeatSentence': 10,
    'speakMissingWord': 10,
    'situationSpeaking': 10,
    'sceneDescriptionSpeaking': 10,
    'yesNoSpeaking': 10,
    'speakSynonym': 10,
    'dialogueRoleplay': 10,
    'pronunciationFocus': 10,
    'speakOpposite': 10,
    'dailyExpression': 10,

    // 2. Listening (10 Games)
    'audioFillBlanks': 10,
    'audioMultipleChoice': 10,
    'audioSentenceOrder': 10,
    'audioTrueFalse': 10,
    'soundImageMatch': 10,
    'fastSpeechDecoder': 10,
    'emotionRecognition': 10,
    'detailSpotlight': 10,
    'listeningInference': 10,
    'ambientId': 10,

    // 3. Reading (12 Games)
    'readAndAnswer': 10,
    'findWordMeaning': 10,
    'trueFalseReading': 10,
    'sentenceOrderReading': 10,
    'readingSpeedCheck': 10,
    'guessTitle': 10,
    'readAndMatch': 10,
    'paragraphSummary': 10,
    'readingInference': 10,
    'readingConclusion': 10,
    'clozeTest': 10,
    'skimmingScanning': 10,

    // 4. Writing (11 Games)
    'sentenceBuilder': 10,
    'completeSentence': 10,
    'describeSituationWriting': 10,
    'fixTheSentence': 10,
    'shortAnswerWriting': 10,
    'opinionWriting': 10,
    'dailyJournal': 10,
    'summarizeStoryWriting': 10,
    'writingEmail': 10,
    'correctionWriting': 10,
    'essayDrafting': 10,

    // 5. Grammar (19 Games)
    'grammarQuest': 10,
    'sentenceCorrection': 10,
    'wordReorder': 10,
    'tenseMastery': 10,
    'partsOfSpeech': 10,
    'subjectVerbAgreement': 10,
    'clauseConnector': 10,
    'voiceSwap': 10,
    'questionFormatter': 10,
    'articleInsertion': 10,
    'modifierPlacement': 10,
    'modalsSelection': 10,
    'prepositionChoice': 10,
    'pronounResolution': 10,
    'punctuationMastery': 10,
    'relativeClauses': 10,
    'conditionals': 10,
    'conjunctions': 10,
    'directIndirectSpeech': 10,

    // 6. Vocabulary (12 Games)
    'flashcards': 10,
    'synonymSearch': 10,
    'antonymSearch': 10,
    'contextClues': 10,
    'phrasalVerbs': 10,
    'idioms': 10,
    'academicWord': 10,
    'topicVocab': 10,
    'wordFormation': 10,
    'prefixSuffix': 10,
    'collocations': 10,
    'contextualUsage': 10,

    // 7. Accent (12 Games)
    'minimalPairs': 10,
    'intonationMimic': 10,
    'syllableStress': 10,
    'wordLinking': 10,
    'shadowingChallenge': 10,
    'vowelDistinction': 10,
    'consonantClarity': 10,
    'pitchPatternMatch': 10,
    'speedVariance': 10,
    'dialectDrill': 10,
    'connectedSpeech': 10,
    'pitchModulation': 10,

    // 8. Roleplay (10 Games)
    'branchingDialogue': 10,
    'situationalResponse': 10,
    'jobInterview': 10,
    'medicalConsult': 10,
    'gourmetOrder': 10,
    'travelDesk': 10,
    'conflictResolver': 10,
    'elevatorPitch': 10,
    'socialSpark': 10,
    'emergencyHub': 10,

    // 9. Elite Mastery (4 Games)
    'storyBuilder': 10,
    'idiomMatch': 10,
    'speedSpelling': 10,
    'accentShadowing': 10,

    // 10. Kids Zone (22 Games)
    'alphabet': 10,
    'numbers': 10,
    'colors': 10,
    'shapes': 10,
    'animals': 10,
    'fruits': 10,
    'family': 10,
    'school': 10,
    'verbs': 10,
    'routine': 10,
    'emotions': 10,
    'prepositions': 10,
    'phonics': 10,
    'day_night': 10,
    'nature': 10,
    'home_kids': 10,
    'food_kids': 10,
    'transport': 10,
    'time': 10,
    'opposites': 10,
    'body_parts': 10,
    'clothing': 10,

    // Meta-categories (9 Categories)
    'reading': 10,
    'writing': 10,
    'speaking': 10,
    'grammar': 10,
    'roleplay': 10,
    'accent': 10,
    'listening': 10,
    'vocabulary': 10,
    'elitemastery': 10,
  };
}
