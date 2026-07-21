/// Centralized constants for the Vowl game domain.
///
/// Extracted to a single source of truth, eliminating the critical duplication
/// of [kDefaultUnlockedLevels] previously copy-pasted verbatim across both
/// [UserEntity] and [UserModel] (100+ lines each).
///
/// All repository implementations and domain entities import from here.
///
/// ### Internal composition
/// [kDefaultUnlockedLevels] is composed from private per-category sub-maps
/// (`_kSpeakingLevels`, `_kListeningLevels`, ... `_kKidsZoneLevels`, etc.) via
/// const spreads. This is more than an organizational nicety: [kKidsGameTypes]
/// is *derived* from `_kKidsZoneLevels.keys`, so the Kids Zone identifiers can
/// never drift out of sync between the two collections the way two
/// hand-typed, independently-maintained literals could. Adding a new Kids
/// Zone game only requires touching `_kKidsZoneLevels`; every place that
/// depends on "is this a kids game" or "what's its default level" updates
/// automatically. The public surface (exactly [kDefaultUnlockedLevels] and
/// [kKidsGameTypes]) is unchanged, so this is a pure internal refactor.
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
  // Milestone Rewards
  // ---------------------------------------------------------------------------

  /// Coin reward for reaching each streak-day milestone. The single source of
  /// truth consulted server-side by
  /// `GamificationRepositoryImpl.claimStreakMilestone`, so a caller can never
  /// claim an unrecognized milestone or supply its own reward amount.
  ///
  /// Previously duplicated as a private `_streakMilestones` field inside
  /// `ProgressionBloc` with no server-side counterpart to validate against.
  static const Map<int, int> kStreakMilestoneRewards = {
    7: 100,
    14: 250,
    30: 500,
    50: 1000,
    100: 2500,
    200: 5000,
    300: 7500,
    365: 10000,
    500: 12500,
    730: 20000, // 2 years
    1000: 25000,
  };

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

  static const List<String> kDefaultVowlOwnedMascots = [
    'vowl_prime',
    'silver_wing',
    'crystal_swan',
    'neon_parrot',
  ];

  // ---------------------------------------------------------------------------
  // Kids Game Type Registry
  // ---------------------------------------------------------------------------

  /// The complete set of Kids Zone game type identifiers.
  ///
  /// Used by [GamificationRepositoryImpl.updateUserRewards] to route rewards
  /// into [kidsCoins] instead of the standard [coins] bucket.
  ///
  /// Derived from [_kKidsZoneLevels] (computed once, on first access, then
  /// cached) rather than a second hand-typed literal — see class doc.
  static final Set<String> kKidsGameTypes = _kKidsZoneLevels.keys.toSet();

  // ---------------------------------------------------------------------------
  // Default Unlocked Levels
  // ---------------------------------------------------------------------------

  /// The full default unlocked-levels map assigned to every new user.
  ///
  /// Every game and category starts at level 1. Previously this was duplicated
  /// verbatim in both [UserEntity] and [UserModel]; it now lives here alone.
  static const Map<String, int> kDefaultUnlockedLevels = {
    ..._kSpeakingLevels,
    ..._kListeningLevels,
    ..._kReadingLevels,
    ..._kWritingLevels,
    ..._kGrammarLevels,
    ..._kVocabularyLevels,
    ..._kAccentLevels,
    ..._kRoleplayLevels,
    ..._kEliteMasteryLevels,
    ..._kKidsZoneLevels,
    ..._kMetaCategoryLevels,
  };

  // 1. Speaking (10 Games)
  static const Map<String, int> _kSpeakingLevels = {
    'repeatSentence': 1,
    'speakMissingWord': 1,
    'situationSpeaking': 1,
    'sceneDescriptionSpeaking': 1,
    'yesNoSpeaking': 1,
    'speakSynonym': 1,
    'dialogueRoleplay': 1,
    'pronunciationFocus': 1,
    'speakOpposite': 1,
    'dailyExpression': 1,
  };

  // 2. Listening (10 Games)
  static const Map<String, int> _kListeningLevels = {
    'audioFillBlanks': 1,
    'audioMultipleChoice': 1,
    'audioSentenceOrder': 1,
    'audioTrueFalse': 1,
    'soundImageMatch': 1,
    'fastSpeechDecoder': 1,
    'emotionRecognition': 1,
    'detailSpotlight': 1,
    'listeningInference': 1,
    'ambientId': 1,
  };

  // 3. Reading (12 Games)
  static const Map<String, int> _kReadingLevels = {
    'readAndAnswer': 1,
    'findWordMeaning': 1,
    'trueFalseReading': 1,
    'sentenceOrderReading': 1,
    'readingSpeedCheck': 1,
    'guessTitle': 1,
    'readAndMatch': 1,
    'paragraphSummary': 1,
    'readingInference': 1,
    'readingConclusion': 1,
    'clozeTest': 1,
    'skimmingScanning': 1,
  };

  // 4. Writing (11 Games)
  static const Map<String, int> _kWritingLevels = {
    'sentenceBuilder': 1,
    'completeSentence': 1,
    'describeSituationWriting': 1,
    'fixTheSentence': 1,
    'shortAnswerWriting': 1,
    'opinionWriting': 1,
    'dailyJournal': 1,
    'summarizeStoryWriting': 1,
    'writingEmail': 1,
    'correctionWriting': 1,
    'essayDrafting': 1,
  };

  // 5. Grammar (19 Games)
  static const Map<String, int> _kGrammarLevels = {
    'grammarQuest': 1,
    'sentenceCorrection': 1,
    'wordReorder': 1,
    'tenseMastery': 1,
    'partsOfSpeech': 1,
    'subjectVerbAgreement': 1,
    'clauseConnector': 1,
    'voiceSwap': 1,
    'questionFormatter': 1,
    'articleInsertion': 1,
    'modifierPlacement': 1,
    'modalsSelection': 1,
    'prepositionChoice': 1,
    'pronounResolution': 1,
    'punctuationMastery': 1,
    'relativeClauses': 1,
    'conditionals': 1,
    'conjunctions': 1,
    'directIndirectSpeech': 1,
  };

  // 6. Vocabulary (12 Games)
  static const Map<String, int> _kVocabularyLevels = {
    'flashcards': 1,
    'synonymSearch': 1,
    'antonymSearch': 1,
    'contextClues': 1,
    'phrasalVerbs': 1,
    'idioms': 1,
    'academicWord': 1,
    'topicVocab': 1,
    'wordFormation': 1,
    'prefixSuffix': 1,
    'collocations': 1,
    'contextualUsage': 1,
  };

  // 7. Accent (12 Games)
  static const Map<String, int> _kAccentLevels = {
    'minimalPairs': 1,
    'intonationMimic': 1,
    'syllableStress': 1,
    'wordLinking': 1,
    'shadowingChallenge': 1,
    'vowelDistinction': 1,
    'consonantClarity': 1,
    'pitchPatternMatch': 1,
    'speedVariance': 1,
    'dialectDrill': 1,
    'connectedSpeech': 1,
    'pitchModulation': 1,
  };

  // 8. Roleplay (10 Games)
  static const Map<String, int> _kRoleplayLevels = {
    'branchingDialogue': 1,
    'situationalResponse': 1,
    'jobInterview': 1,
    'medicalConsult': 1,
    'gourmetOrder': 1,
    'travelDesk': 1,
    'conflictResolver': 1,
    'elevatorPitch': 1,
    'socialSpark': 1,
    'emergencyHub': 1,
  };

  // 9. Elite Mastery (4 Games)
  static const Map<String, int> _kEliteMasteryLevels = {
    'storyBuilder': 1,
    'idiomMatch': 1,
    'speedSpelling': 1,
    'accentShadowing': 1,
  };

  // 10. Kids Zone (23 Games)
  //
  // This is the single source of truth for Kids Zone game identifiers.
  // [kKidsGameTypes] is derived from this map's keys — do not add a kids
  // game anywhere else without adding it here first.
  static const Map<String, int> _kKidsZoneLevels = {
    'alphabet': 1,
    'numbers': 1,
    'colors': 1,
    'shapes': 1,
    'animals': 1,
    'fruits': 1,
    'family': 1,
    'school': 1,
    'verbs': 1,
    'routine': 1,
    'emotions': 1,
    'prepositions': 1,
    'phonics': 1,
    'day_night': 1,
    'nature': 1,
    'home_kids': 1,
    'food_kids': 1,
    'transport': 1,
    'time': 1,
    'opposites': 1,
    'body_parts': 1,
    'clothing': 1,
    'handwriting': 1,
  };

  // Meta-categories (9 Categories)
  static const Map<String, int> _kMetaCategoryLevels = {
    'reading': 1,
    'writing': 1,
    'speaking': 1,
    'grammar': 1,
    'roleplay': 1,
    'accent': 1,
    'listening': 1,
    'vocabulary': 1,
    'elitemastery': 1,
  };
}
