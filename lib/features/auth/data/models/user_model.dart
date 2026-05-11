import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.fcmToken,
    super.coins,
    super.totalExp,
    super.isAdmin,
    super.currentStreak,
    super.lastLoginDate,
    super.isEmailVerified,
    super.isPremium,
    super.premiumExpiryDate,
    super.categoryStats,
    super.unlockedLevels,
    super.completedLevels,
    super.badges,
    super.streakFreezes,
    super.hintCount,
    super.hintPacks,
    super.doubleXP,
    super.doubleXPExpiry,
    required super.dailyXpHistory,
    super.recentActivities,
    super.lastVipGiftDate,
    super.lastDailyRewardDate,
    super.kidsCoins,
    super.kidsStickers,
    super.kidsMascot,
    super.kidsEquippedSticker,
    super.kidsOwnedAccessories,
    super.kidsEquippedAccessory,
    super.vowlMascot,
    super.vowlEquippedAccessory,
    super.vowlOwnedAccessories = const [],
    super.vowlOwnedMascots = const ['vowl_prime'],
    super.claimedStreakMilestones,
    super.claimedLevelMilestones,
    super.coinHistory,
    super.hasPermanentXPBoost,
    super.lastFreeSpinDate,
    super.lastAdSpinDate,
    super.adSpinsUsedToday,
    super.lastKidsDailyRewardDate,
    super.kidsOwnedFurniture = const ['default_bed', 'default_window'],
    super.kidsEquippedFurniture = const {
      'bed': 'default_bed',
      'window': 'default_window',
    },
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      totalExp: (map['totalExp'] as num?)?.toInt() ?? 0,
      isAdmin: map['isAdmin'] ?? false,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      lastLoginDate: map['lastLoginDate'] != null
          ? (map['lastLoginDate'] as dynamic).toDate()
          : null,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPremium: map['isPremium'] ?? false,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? (map['premiumExpiryDate'] as Timestamp).toDate()
          : null,
      categoryStats: map['categoryStats'] != null
          ? (map['categoryStats'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            )
          : {},
      unlockedLevels: map['unlockedLevels'] != null
          ? (map['unlockedLevels'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            )
          : const {
              'repeatSentence': 1,
              'speakMissingWord': 1,
              'situationSpeaking': 1,
              'sceneDescriptionSpeaking': 1,
              'yesNoSpeaking': 1,
              'speakSynonym': 1,
              'speakOpposite': 1,
              'dailyExpression': 1,
              'audioFillBlanks': 1,
              'audioMultipleChoice': 1,
              'readAndAnswer': 1,
              'findWordMeaning': 1,
              'trueFalseReading': 1,
              'sentenceOrderReading': 1,
              'readingSpeedCheck': 1,
              'guessTitle': 1,
              'readAndMatch': 1,
              'paragraphSummary': 1,
              'sentenceBuilder': 1,
              'completeSentence': 1,
              'describeSituationWriting': 1,
              'fixTheSentence': 1,
              'shortAnswerWriting': 1,
              'opinionWriting': 1,
              'dailyJournal': 1,
              'grammarQuest': 1,
              'sentenceCorrection': 1,
              'wordReorder': 1,
              'pronunciationFocus': 1,
              'minimalPairs': 1,
              'intonationMimic': 1,
              'dialogueRoleplay': 1,
              'branchingDialogue': 1,
              'situationalResponse': 1,
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
            },
      completedLevels: map['completedLevels'] != null
          ? (map['completedLevels'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                (value as List).map((v) => (v as num).toInt()).toList(),
              ),
            )
          : {},
      badges: map['badges'] != null
          ? List<String>.from(map['badges'])
          : const [],
      streakFreezes: (map['streakFreezes'] as num?)?.toInt() ?? 0,
      hintCount: (map['hintCount'] as num?)?.toInt() ?? 3,
      hintPacks: (map['hintPacks'] as num?)?.toInt() ?? 0,
      doubleXP: (map['doubleXP'] as num?)?.toInt() ?? 0,
      doubleXPExpiry: map['doubleXPExpiry'] != null
          ? (map['doubleXPExpiry'] as Timestamp).toDate()
          : null,
      dailyXpHistory: map['dailyXpHistory'] != null
          ? (map['dailyXpHistory'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            )
          : {},
      recentActivities: map['recentActivities'] != null
          ? List<Map<String, dynamic>>.from(map['recentActivities'])
          : [],
      lastVipGiftDate: map['lastVipGiftDate'] != null
          ? (map['lastVipGiftDate'] as Timestamp).toDate()
          : null,
      lastDailyRewardDate: map['lastDailyRewardDate'] != null
          ? (map['lastDailyRewardDate'] as Timestamp).toDate()
          : null,
      lastKidsDailyRewardDate: map['lastKidsDailyRewardDate'] != null
          ? (map['lastKidsDailyRewardDate'] as Timestamp).toDate()
          : null,
      kidsStickers: map['kidsStickers'] != null
          ? List<String>.from(map['kidsStickers'])
          : const [],
      kidsCoins: (map['kidsCoins'] as num?)?.toInt() ?? 0,
      kidsMascot: map['kidsMascot'],
      kidsEquippedSticker: map['kidsEquippedSticker'],
      kidsOwnedAccessories: map['kidsOwnedAccessories'] != null
          ? List<String>.from(map['kidsOwnedAccessories'])
          : const [],
      kidsEquippedAccessory: map['kidsEquippedAccessory'],
      claimedStreakMilestones: map['claimedStreakMilestones'] != null
          ? (map['claimedStreakMilestones'] as List)
                .map((e) => (e as num).toInt())
                .toList()
          : const [],
      claimedLevelMilestones: map['claimedLevelMilestones'] != null
          ? (map['claimedLevelMilestones'] as List)
                .map((e) => (e as num).toInt())
                .toList()
          : const [],
      coinHistory: map['coinHistory'] != null
          ? List<Map<String, dynamic>>.from(map['coinHistory'])
          : const [],
      hasPermanentXPBoost: map['hasPermanentXPBoost'] ?? false,
      lastFreeSpinDate: map['lastFreeSpinDate'] != null
          ? (map['lastFreeSpinDate'] as Timestamp).toDate()
          : null,
      lastAdSpinDate: map['lastAdSpinDate'] != null
          ? (map['lastAdSpinDate'] as Timestamp).toDate()
          : null,
      adSpinsUsedToday: (map['adSpinsUsedToday'] as num?)?.toInt() ?? 0,
      vowlMascot: map['vowlMascot'],
      vowlEquippedAccessory: map['vowlEquippedAccessory'],
      vowlOwnedAccessories: map['vowlOwnedAccessories'] != null
          ? List<String>.from(map['vowlOwnedAccessories'])
          : const [],
      vowlOwnedMascots: map['vowlOwnedMascots'] != null
          ? List<String>.from(map['vowlOwnedMascots'])
          : const ['vowl_prime'],
      kidsOwnedFurniture: map['kidsOwnedFurniture'] != null
          ? List<String>.from(map['kidsOwnedFurniture'])
          : const ['default_bed', 'default_window'],
      kidsEquippedFurniture: map['kidsEquippedFurniture'] != null
          ? Map<String, String>.from(map['kidsEquippedFurniture'])
          : const {
              'bed': 'default_bed',
              'window': 'default_window',
            },
    );
  }

  @override
  UserModel copyWith({
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
    DateTime? lastKidsDailyRewardDate,
    String? vowlMascot,
    String? vowlEquippedAccessory,
    List<String>? vowlOwnedAccessories,
    List<String>? vowlOwnedMascots,
    List<String>? kidsOwnedFurniture,
    Map<String, String>? kidsEquippedFurniture,
  }) {
    return UserModel(
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
      lastKidsDailyRewardDate: lastKidsDailyRewardDate ?? this.lastKidsDailyRewardDate,
      vowlMascot: vowlMascot ?? this.vowlMascot,
      vowlEquippedAccessory:
          vowlEquippedAccessory ?? this.vowlEquippedAccessory,
      vowlOwnedAccessories:
          vowlOwnedAccessories ?? this.vowlOwnedAccessories,
      vowlOwnedMascots: vowlOwnedMascots ?? this.vowlOwnedMascots,
      kidsOwnedFurniture: kidsOwnedFurniture ?? this.kidsOwnedFurniture,
      kidsEquippedFurniture: kidsEquippedFurniture ?? this.kidsEquippedFurniture,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'coins': coins,
      'totalExp': totalExp,
      'isAdmin': isAdmin,
      'currentStreak': currentStreak,
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null,
      'isEmailVerified': isEmailVerified,
      'isPremium': isPremium,
      'premiumExpiryDate': premiumExpiryDate != null
          ? Timestamp.fromDate(premiumExpiryDate!)
          : null,
      'categoryStats': categoryStats,
      'unlockedLevels': unlockedLevels,
      'completedLevels': completedLevels,
      'badges': badges,
      'streakFreezes': streakFreezes,
      'hintCount': hintCount,
      'hintPacks': hintPacks,
      'doubleXP': doubleXP,
      'doubleXPExpiry': doubleXPExpiry != null
          ? Timestamp.fromDate(doubleXPExpiry!)
          : null,
      'dailyXpHistory': dailyXpHistory,
      'recentActivities': recentActivities,
      'lastVipGiftDate': lastVipGiftDate != null
          ? Timestamp.fromDate(lastVipGiftDate!)
          : null,
      'lastDailyRewardDate': lastDailyRewardDate != null
          ? Timestamp.fromDate(lastDailyRewardDate!)
          : null,
      'lastKidsDailyRewardDate': lastKidsDailyRewardDate != null
          ? Timestamp.fromDate(lastKidsDailyRewardDate!)
          : null,
      'kidsCoins': kidsCoins,
      'kidsStickers': kidsStickers,
      'kidsMascot': kidsMascot,
      'kidsEquippedSticker': kidsEquippedSticker,
      'kidsOwnedAccessories': kidsOwnedAccessories,
      'kidsEquippedAccessory': kidsEquippedAccessory,
      'claimedStreakMilestones': claimedStreakMilestones,
      'claimedLevelMilestones': claimedLevelMilestones,
      'coinHistory': coinHistory,
      'hasPermanentXPBoost': hasPermanentXPBoost,
      'lastFreeSpinDate': lastFreeSpinDate != null
          ? Timestamp.fromDate(lastFreeSpinDate!)
          : null,
      'lastAdSpinDate': lastAdSpinDate != null
          ? Timestamp.fromDate(lastAdSpinDate!)
          : null,
      'adSpinsUsedToday': adSpinsUsedToday,
      'vowlMascot': vowlMascot,
      'vowlEquippedAccessory': vowlEquippedAccessory,
      'vowlOwnedAccessories': vowlOwnedAccessories,
      'vowlOwnedMascots': vowlOwnedMascots,
      'kidsOwnedFurniture': kidsOwnedFurniture,
      'kidsEquippedFurniture': kidsEquippedFurniture,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) =>
      UserModel.fromJson(map);
}
