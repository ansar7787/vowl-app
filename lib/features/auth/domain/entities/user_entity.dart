import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Central domain entity representing a User session in the Vowl ecosystem.
///
/// Implements high-performance custom Deep Collection Equality overrides for [operator ==] and [hashCode]
/// to prevent false state changes in BLoCs and eliminate redundant UI re-renders on collections.
@immutable
class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? fcmToken;
  final int coins;
  final int totalExp;
  final bool isAdmin;
  final int currentStreak;
  final DateTime? lastLoginDate;
  final bool isPremium;
  final bool isEmailVerified;
  final DateTime? premiumExpiryDate;
  final Map<String, int> categoryStats;
  final Map<String, int> unlockedLevels;
  final Map<String, List<int>> completedLevels;
  final List<String> badges;
  final int streakFreezes;
  final int hintCount;
  final int hintPacks;
  final int doubleXP;
  final DateTime? doubleXPExpiry;
  final Map<String, int> dailyXpHistory;
  final List<Map<String, dynamic>> recentActivities;
  final DateTime? lastVipGiftDate;
  final DateTime? lastDailyRewardDate;
  final int kidsCoins;
  final List<String> kidsStickers;
  final String? kidsMascot;
  final String? kidsEquippedSticker;
  final List<String> kidsOwnedAccessories;
  final String? kidsEquippedAccessory;
  final String? vowlMascot;
  final String? vowlEquippedAccessory;
  final List<String> vowlOwnedAccessories;
  final List<String> vowlOwnedMascots;
  final List<int> claimedStreakMilestones;
  final List<int> claimedLevelMilestones;
  final List<Map<String, dynamic>> coinHistory;
  final bool hasPermanentXPBoost;
  final DateTime? lastFreeSpinDate;
  final DateTime? lastAdSpinDate;
  final int adSpinsUsedToday;
  final DateTime? lastKidsDailyRewardDate;
  final List<String> kidsOwnedFurniture;
  final Map<String, String> kidsEquippedFurniture;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
    this.coins = 0,
    this.totalExp = 0,
    this.isAdmin = false,
    this.currentStreak = 0,
    this.lastLoginDate,
    this.isEmailVerified = false,
    this.isPremium = false,
    this.premiumExpiryDate,
    this.categoryStats = const {},
    this.unlockedLevels = const {
      // 1. Speaking (10 Games)
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

      // 2. Listening (10 Games)
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

      // 3. Reading (12 Games)
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

      // 4. Writing (11 Games)
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

      // 5. Grammar (19 Games)
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

      // 6. Vocabulary (12 Games)
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

      // 7. Accent (12 Games)
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

      // 8. Roleplay (10 Games)
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

      // 9. Elite Mastery (4 Games)
      'storyBuilder': 1,
      'idiomMatch': 1,
      'speedSpelling': 1,
      'accentShadowing': 1,

      // 10. Kids Zone (22 Games)
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
      'body_parts': 1, // Retained matching name representation
      'clothing': 1,

      // Categories (9 Categories)
      'reading': 1,
      'writing': 1,
      'speaking': 1,
      'grammar': 1,
      'roleplay': 1,
      'accent': 1,
      'listening': 1,
      'vocabulary': 1,
      'elitemastery': 1,
    },
    this.completedLevels = const {},
    this.badges = const [],
    this.streakFreezes = 0,
    this.hintCount = 0,
    this.hintPacks = 0,
    this.doubleXP = 0,
    this.doubleXPExpiry,
    this.dailyXpHistory = const {},
    this.recentActivities = const [],
    this.lastVipGiftDate,
    this.lastDailyRewardDate,
    this.lastKidsDailyRewardDate,
    this.kidsOwnedFurniture = const ['default_bed', 'default_window'],
    this.kidsEquippedFurniture = const {
      'bed': 'default_bed',
      'window': 'default_window',
    },
    this.kidsCoins = 0,
    this.kidsStickers = const [],
    this.kidsMascot,
    this.kidsEquippedSticker,
    this.kidsOwnedAccessories = const [],
    this.kidsEquippedAccessory,
    this.vowlMascot,
    this.vowlEquippedAccessory,
    this.vowlOwnedAccessories = const [],
    this.vowlOwnedMascots = const ['vowl_prime'],
    this.claimedStreakMilestones = const [],
    this.claimedLevelMilestones = const [],
    this.coinHistory = const [],
    this.hasPermanentXPBoost = false,
    this.lastFreeSpinDate,
    this.lastAdSpinDate,
    this.adSpinsUsedToday = 0,
  });

  int get level => (totalExp / 100).floor() + 1;

  int get totalLevelsCompleted {
    int count = 0;
    completedLevels.forEach((_, levels) => count += levels.length);
    return count;
  }

  // Mastery Getters
  int get speakingMastery => getCategoryProgress(QuestType.speaking);
  int get readingMastery => getCategoryProgress(QuestType.reading);
  int get writingMastery => getCategoryProgress(QuestType.writing);
  int get vocabularyMastery => getCategoryProgress(QuestType.vocabulary);
  int get grammarMastery => getCategoryProgress(QuestType.grammar);
  int get listeningMastery => getCategoryProgress(QuestType.listening);
  int get accentMastery => getCategoryProgress(QuestType.accent);
  int get roleplayMastery => getCategoryProgress(QuestType.roleplay);

  int getCategoryProgress(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    if (subtypes.isEmpty) return 0;

    int maxProgress = 0;
    for (final subtype in subtypes) {
      final progress = categoryStats[subtype.name] ?? 0;
      if (progress > maxProgress) {
        maxProgress = progress;
      }
    }
    return maxProgress;
  }

  int getTotalCategoryLevelsCleared(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    if (subtypes.isEmpty) return 0;

    int totalCleared = 0;
    for (final subtype in subtypes) {
      if (unlockedLevels.containsKey(subtype.name)) {
        final level = unlockedLevels[subtype.name]!;
        if (level > 1) {
          totalCleared += (level - 1);
        }
      }
    }
    return totalCleared;
  }

  int getMaxCategoryLevels(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    return subtypes.length * 200;
  }

  int getEffectiveLevel(String categoryOrGame, int level) {
    if (level <= 200) return level;
    return 150 + ((level - 201) % 50);
  }

  List<String> get earnedBadges => badges;

  bool get isDoubleXPActive {
    if (doubleXPExpiry == null) return false;
    return doubleXPExpiry!.isAfter(DateTime.now());
  }

  bool get isVipGiftAvailable {
    if (!isPremium) return false;
    if (lastVipGiftDate == null) return true;
    final now = DateTime.now();
    final lastGift = lastVipGiftDate!;
    return lastGift.year != now.year ||
        lastGift.month != now.month ||
        lastGift.day != now.day;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final MapEquality mapEquals = const MapEquality();
    final ListEquality listEquals = const ListEquality();
    final DeepCollectionEquality deepEquals = const DeepCollectionEquality();

    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.fcmToken == fcmToken &&
        other.coins == coins &&
        other.totalExp == totalExp &&
        other.isAdmin == isAdmin &&
        other.currentStreak == currentStreak &&
        other.lastLoginDate == lastLoginDate &&
        other.isPremium == isPremium &&
        other.isEmailVerified == isEmailVerified &&
        other.premiumExpiryDate == premiumExpiryDate &&
        mapEquals.equals(other.categoryStats, categoryStats) &&
        mapEquals.equals(other.unlockedLevels, unlockedLevels) &&
        deepEquals.equals(other.completedLevels, completedLevels) &&
        listEquals.equals(other.badges, badges) &&
        other.streakFreezes == streakFreezes &&
        other.hintCount == hintCount &&
        other.hintPacks == hintPacks &&
        other.doubleXP == doubleXP &&
        other.doubleXPExpiry == doubleXPExpiry &&
        mapEquals.equals(other.dailyXpHistory, dailyXpHistory) &&
        deepEquals.equals(other.recentActivities, recentActivities) &&
        other.lastVipGiftDate == lastVipGiftDate &&
        other.lastDailyRewardDate == lastDailyRewardDate &&
        other.kidsCoins == kidsCoins &&
        listEquals.equals(other.kidsStickers, kidsStickers) &&
        other.kidsMascot == kidsMascot &&
        other.kidsEquippedSticker == kidsEquippedSticker &&
        listEquals.equals(other.kidsOwnedAccessories, kidsOwnedAccessories) &&
        other.kidsEquippedAccessory == kidsEquippedAccessory &&
        other.vowlMascot == vowlMascot &&
        other.vowlEquippedAccessory == vowlEquippedAccessory &&
        listEquals.equals(other.vowlOwnedAccessories, vowlOwnedAccessories) &&
        listEquals.equals(other.vowlOwnedMascots, vowlOwnedMascots) &&
        listEquals.equals(other.claimedStreakMilestones, claimedStreakMilestones) &&
        listEquals.equals(other.claimedLevelMilestones, claimedLevelMilestones) &&
        deepEquals.equals(other.coinHistory, coinHistory) &&
        other.hasPermanentXPBoost == hasPermanentXPBoost &&
        other.lastFreeSpinDate == lastFreeSpinDate &&
        other.lastAdSpinDate == lastAdSpinDate &&
        other.adSpinsUsedToday == adSpinsUsedToday &&
        other.lastKidsDailyRewardDate == lastKidsDailyRewardDate &&
        listEquals.equals(other.kidsOwnedFurniture, kidsOwnedFurniture) &&
        mapEquals.equals(other.kidsEquippedFurniture, kidsEquippedFurniture);
  }

  @override
  int get hashCode {
    final Object hasher = Object.hashAll([
      id,
      email,
      displayName,
      photoUrl,
      fcmToken,
      coins,
      totalExp,
      isAdmin,
      currentStreak,
      lastLoginDate,
      isPremium,
      isEmailVerified,
      premiumExpiryDate,
      const MapEquality().hash(categoryStats),
      const MapEquality().hash(unlockedLevels),
      const DeepCollectionEquality().hash(completedLevels),
      const ListEquality().hash(badges),
      streakFreezes,
      hintCount,
      hintPacks,
    ]);
    final Object hasher2 = Object.hashAll([
      doubleXP,
      doubleXPExpiry,
      const MapEquality().hash(dailyXpHistory),
      const DeepCollectionEquality().hash(recentActivities),
      lastVipGiftDate,
      lastDailyRewardDate,
      kidsCoins,
      const ListEquality().hash(kidsStickers),
      kidsMascot,
      kidsEquippedSticker,
      const ListEquality().hash(kidsOwnedAccessories),
      kidsEquippedAccessory,
      vowlMascot,
      vowlEquippedAccessory,
      const ListEquality().hash(vowlOwnedAccessories),
      const ListEquality().hash(vowlOwnedMascots),
      const ListEquality().hash(claimedStreakMilestones),
      const ListEquality().hash(claimedLevelMilestones),
      const DeepCollectionEquality().hash(coinHistory),
      hasPermanentXPBoost,
    ]);
    final Object hasher3 = Object.hashAll([
      lastFreeSpinDate,
      lastAdSpinDate,
      adSpinsUsedToday,
      lastKidsDailyRewardDate,
      const ListEquality().hash(kidsOwnedFurniture),
      const MapEquality().hash(kidsEquippedFurniture),
    ]);
    return Object.hash(hasher, hasher2, hasher3);
  }

  UserEntity copyWith({
    List<String>? badges,
    Map<String, int>? categoryStats,
    List<int>? claimedLevelMilestones,
    List<int>? claimedStreakMilestones,
    List<Map<String, dynamic>>? coinHistory,
    int? coins,
    Map<String, List<int>>? completedLevels,
    int? currentStreak,
    Map<String, int>? dailyXpHistory,
    String? displayName,
    int? doubleXP,
    DateTime? doubleXPExpiry,
    int? hintCount,
    int? hintPacks,
    bool? isAdmin,
    bool? isEmailVerified,
    bool? isPremium,
    int? kidsCoins,
    String? kidsEquippedAccessory,
    String? kidsEquippedSticker,
    String? kidsMascot,
    List<String>? kidsOwnedAccessories,
    List<String>? kidsStickers,
    DateTime? lastDailyRewardDate,
    DateTime? lastKidsDailyRewardDate,
    DateTime? lastLoginDate,
    DateTime? lastVipGiftDate,
    String? photoUrl,
    String? fcmToken,
    DateTime? premiumExpiryDate,
    List<Map<String, dynamic>>? recentActivities,
    int? streakFreezes,
    int? totalExp,
    Map<String, int>? unlockedLevels,
    bool? hasPermanentXPBoost,
    DateTime? lastFreeSpinDate,
    DateTime? lastAdSpinDate,
    int? adSpinsUsedToday,
    String? vowlMascot,
    String? vowlEquippedAccessory,
    List<String>? vowlOwnedAccessories,
    List<String>? vowlOwnedMascots,
    List<String>? kidsOwnedFurniture,
    Map<String, String>? kidsEquippedFurniture,
  }) {
    return UserEntity(
      id: id,
      email: email,
      badges: badges ?? this.badges,
      categoryStats: categoryStats ?? this.categoryStats,
      claimedLevelMilestones:
          claimedLevelMilestones ?? this.claimedLevelMilestones,
      claimedStreakMilestones:
          claimedStreakMilestones ?? this.claimedStreakMilestones,
      coinHistory: coinHistory ?? this.coinHistory,
      coins: coins ?? this.coins,
      completedLevels: completedLevels ?? this.completedLevels,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyXpHistory: dailyXpHistory ?? this.dailyXpHistory,
      displayName: displayName ?? this.displayName,
      doubleXP: doubleXP ?? this.doubleXP,
      doubleXPExpiry: doubleXPExpiry ?? this.doubleXPExpiry,
      hintCount: hintCount ?? this.hintCount,
      hintPacks: hintPacks ?? this.hintPacks,
      isAdmin: isAdmin ?? this.isAdmin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
      kidsCoins: kidsCoins ?? this.kidsCoins,
      kidsEquippedAccessory:
          kidsEquippedAccessory ?? this.kidsEquippedAccessory,
      kidsEquippedSticker: kidsEquippedSticker ?? this.kidsEquippedSticker,
      kidsMascot: kidsMascot ?? this.kidsMascot,
      kidsOwnedAccessories: kidsOwnedAccessories ?? this.kidsOwnedAccessories,
      kidsStickers: kidsStickers ?? this.kidsStickers,
      lastDailyRewardDate: lastDailyRewardDate ?? this.lastDailyRewardDate,
      lastKidsDailyRewardDate: lastKidsDailyRewardDate ?? this.lastKidsDailyRewardDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastVipGiftDate: lastVipGiftDate ?? this.lastVipGiftDate,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      recentActivities: recentActivities ?? this.recentActivities,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      totalExp: totalExp ?? this.totalExp,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      hasPermanentXPBoost: hasPermanentXPBoost ?? this.hasPermanentXPBoost,
      lastFreeSpinDate: lastFreeSpinDate ?? this.lastFreeSpinDate,
      lastAdSpinDate: lastAdSpinDate ?? this.lastAdSpinDate,
      adSpinsUsedToday: adSpinsUsedToday ?? this.adSpinsUsedToday,
      vowlMascot: vowlMascot ?? this.vowlMascot,
      vowlEquippedAccessory:
          vowlEquippedAccessory ?? this.vowlEquippedAccessory,
      vowlOwnedAccessories:
          vowlOwnedAccessories ?? this.vowlOwnedAccessories,
      vowlOwnedMascots: vowlOwnedMascots ?? this.vowlOwnedMascots,
      kidsOwnedFurniture: kidsOwnedFurniture ?? this.kidsOwnedFurniture,
      kidsEquippedFurniture:
          kidsEquippedFurniture ?? this.kidsEquippedFurniture,
    );
  }
}
