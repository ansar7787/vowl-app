import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class UserEntity extends Equatable {
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
      // Speaking
      'repeatSentence': 1,
      'speakMissingWord': 1,
      'situationSpeaking': 1,
      'sceneDescriptionSpeaking': 1,
      'yesNoSpeaking': 1,
      'speakSynonym': 1,
      'speakOpposite': 1,
      'dailyExpression': 1,
      // Listening
      'audioFillBlanks': 1,
      'audioMultipleChoice': 1,
      // Reading
      'readAndAnswer': 1,
      'findWordMeaning': 1,
      'trueFalseReading': 1,
      'sentenceOrderReading': 1,
      'readingSpeedCheck': 1,
      'guessTitle': 1,
      'readAndMatch': 1,
      'paragraphSummary': 1,
      // Writing
      'sentenceBuilder': 1,
      'completeSentence': 1,
      'describeSituationWriting': 1,
      'fixTheSentence': 1,
      'shortAnswerWriting': 1,
      'opinionWriting': 1,
      'dailyJournal': 1,
      // Grammar
      'grammarQuest': 1,
      'sentenceCorrection': 1,
      'wordReorder': 1,
      // Accent
      'pronunciationFocus': 1,
      'minimalPairs': 1,
      'intonationMimic': 1,
      // Roleplay
      'dialogueRoleplay': 1,
      'branchingDialogue': 1,
      'situationalResponse': 1,
      // Categories (for backward compatibility or summary)
      'reading': 1,
      'writing': 1,
      'speaking': 1,
      'grammar': 1,
      'roleplay': 1,
      'accent': 1,
      'listening': 1,
      // Kids Zone (21 Games)
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
      'time': 1,
      'opposites': 1,
      'day_night': 1,
      'nature': 1,
      'home_kids': 1,
      'food_kids': 1,
      'transport': 1,
      'body_parts': 1,
      'clothing': 1,
      // Elite Mastery
      'storyBuilder': 1,
      'idiomMatch': 1,
      'speedSpelling': 1,
      'accentShadowing': 1,
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

  // Mastery Getters (Dynamically derived from categoryStats for children)
  int get speakingMastery => getCategoryProgress(QuestType.speaking);
  int get readingMastery => getCategoryProgress(QuestType.reading);
  int get writingMastery => getCategoryProgress(QuestType.writing);
  int get vocabularyMastery => getCategoryProgress(QuestType.vocabulary);
  int get grammarMastery => getCategoryProgress(QuestType.grammar);
  int get listeningMastery => getCategoryProgress(QuestType.listening);
  int get accentMastery => getCategoryProgress(QuestType.accent);
  int get roleplayMastery => getCategoryProgress(QuestType.roleplay);

  /// Calculates the highest progress among subtypes in a category.
  /// This provides a better sense of achievement for new users.
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

  /// Calculates the total number of levels cleared across all games in a category.
  /// This provides a cumulative progression metric that encourages playing all games.
  int getTotalCategoryLevelsCleared(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    if (subtypes.isEmpty) return 0;

    int totalCleared = 0;

    for (final subtype in subtypes) {
      if (unlockedLevels.containsKey(subtype.name)) {
        // If they are on level N, they have cleared N-1 levels.
        final level = unlockedLevels[subtype.name]!;
        if (level > 1) {
          totalCleared += (level - 1);
        }
      }
    }

    return totalCleared;
  }

  /// Calculates the maximum theoretical levels for a category (200 levels per active game).
  int getMaxCategoryLevels(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    return subtypes.length * 200;
  }

  /// Returns the effective level for content fetching.
  /// Beyond level 200, we loop back to high-difficulty content (150-200)
  /// to ensure zero running cost for generation while providing infinite play.
  int getEffectiveLevel(String categoryOrGame, int level) {
    if (level <= 200) return level;
    // Map Level 201+ to a loop between 150 and 200
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
    // Check if it's a different day
    return lastGift.year != now.year ||
        lastGift.month != now.month ||
        lastGift.day != now.day;
  }

  @override
  List<Object?> get props => [
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
    isEmailVerified,
    isPremium,
    premiumExpiryDate,
    categoryStats,
    unlockedLevels,
    completedLevels,
    badges,
    streakFreezes,
    hintCount,
    hintPacks,
    doubleXP,
    doubleXPExpiry,
    dailyXpHistory,
    recentActivities,
    lastVipGiftDate,
    lastDailyRewardDate,
    kidsCoins,
    kidsStickers,
    kidsMascot,
    kidsEquippedSticker,
    kidsOwnedAccessories,
    kidsEquippedAccessory,
    vowlMascot,
    vowlEquippedAccessory,
    vowlOwnedAccessories,
    vowlOwnedMascots,
    claimedStreakMilestones,
    claimedLevelMilestones,
    coinHistory,
    hasPermanentXPBoost,
    lastFreeSpinDate,
    lastAdSpinDate,
    adSpinsUsedToday,
    lastKidsDailyRewardDate,
    kidsOwnedFurniture,
    kidsEquippedFurniture,
  ];

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
