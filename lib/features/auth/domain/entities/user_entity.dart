import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';

// ---------------------------------------------------------------------------
// Sentinel for nullable copyWith fields
// ---------------------------------------------------------------------------

/// Private sentinel used to distinguish "caller did not pass this argument"
/// from an explicit [null] in [UserEntity.copyWith].
///
/// This enables callers to clear nullable fields:
/// ```dart
/// entity.copyWith(doubleXPExpiry: null); // clears the expiry
/// entity.copyWith();                     // preserves existing expiry
/// ```
const _absent = _Absent();

@immutable
final class _Absent {
  const _Absent();
}

// ---------------------------------------------------------------------------
// UserEntity
// ---------------------------------------------------------------------------

/// Central domain entity representing a user session in the Vowl ecosystem.
///
/// ### Equality
/// Implements deep collection equality via static [_mapEq], [_listEq], and
/// [_deepEq] constants — allocated once, not per comparison call — preventing
/// redundant UI re-renders in BLoCs when collection content is unchanged.
///
/// ### copyWith & nullable fields
/// All nullable fields accept an explicit `null` to clear their value:
/// ```dart
/// user.copyWith(premiumExpiryDate: null); // removes expiry
/// user.copyWith(coins: 500);              // updates coins, keeps everything else
/// ```
@immutable
class UserEntity {
  // Static equality helpers — const, allocated once per class, not per call.
  static const _mapEq = MapEquality<dynamic, dynamic>();
  static const _listEq = ListEquality<dynamic>();
  static const _deepEq = DeepCollectionEquality();

  /// Unique Firebase authentication identifier.
  final String id;

  /// User's email address.
  final String email;

  /// Optional display name.
  final String? displayName;

  /// Optional avatar URL.
  final String? photoUrl;

  /// Cloud Messaging device registration token.
  final String? fcmToken;

  /// Available coin balance.
  final int coins;

  /// Lifetime accumulated experience points.
  final int totalExp;

  /// Whether the user possesses administrative privileges.
  final bool isAdmin;

  /// Current active daily login streak in days.
  final int currentStreak;

  /// Timestamp of the user's most recent login.
  final DateTime? lastLoginDate;

  /// Whether the user has an active premium subscription.
  final bool isPremium;

  /// Whether the user's email address has been verified.
  final bool isEmailVerified;

  /// Timestamp when the premium subscription expires.
  final DateTime? premiumExpiryDate;

  /// Category mastery percentages keyed by category identifier.
  final Map<String, int> categoryStats;

  /// Highest unlocked level index keyed by game type.
  final Map<String, int> unlockedLevels;

  /// Completed level indices keyed by game type.
  final Map<String, List<int>> completedLevels;

  /// Star ratings earned keyed by game type and level string.
  final Map<String, Map<String, int>> starRatings;

  /// Identifiers of all badges unlocked by the user.
  final List<String> badges;

  /// Count of available streak freeze tokens.
  final int streakFreezes;

  /// Count of individual hint tokens.
  final int hintCount;

  /// Count of bulk hint packs available.
  final int hintPacks;

  /// Count of available double XP tokens.
  final int doubleXP;

  /// Timestamp when active double XP multiplier expires.
  final DateTime? doubleXPExpiry;

  /// Daily XP earnings history keyed by date string.
  final Map<String, int> dailyXpHistory;

  /// Recent activity event logs.
  final List<Map<String, dynamic>> recentActivities;

  /// Timestamp of the last VIP gift redemption.
  final DateTime? lastVipGiftDate;

  /// Timestamp of the last daily reward claim.
  final DateTime? lastDailyRewardDate;

  /// Timestamp of the last kids daily reward claim.
  final DateTime? lastKidsDailyRewardDate;

  /// Kids-specific coin balance.
  final int kidsCoins;

  /// List of sticker asset identifiers collected in kids zone.
  final List<String> kidsStickers;

  /// Currently selected mascot identifier for kids zone.
  final String? kidsMascot;

  /// Currently equipped sticker badge in kids zone.
  final String? kidsEquippedSticker;

  /// List of accessory identifiers unlocked in kids zone.
  final List<String> kidsOwnedAccessories;

  /// Identifier of the currently equipped accessory in kids zone.
  final String? kidsEquippedAccessory;

  /// Identifier of the primary Vowl mascot chosen by user.
  final String? vowlMascot;

  /// Identifier of the equipped Vowl mascot accessory.
  final String? vowlEquippedAccessory;

  /// List of Vowl mascot accessories unlocked.
  final List<String> vowlOwnedAccessories;

  /// List of Vowl mascot characters unlocked.
  final List<String> vowlOwnedMascots;

  /// Streak milestone day counts already claimed.
  final List<int> claimedStreakMilestones;

  /// Level milestones already claimed.
  final List<int> claimedLevelMilestones;

  /// Audit history log of coin transactions.
  final List<Map<String, dynamic>> coinHistory;

  /// Whether the user owns a permanent XP boost.
  final bool hasPermanentXPBoost;

  /// Timestamp of the last free wheel spin.
  final DateTime? lastFreeSpinDate;

  /// Timestamp of the last rewarded ad wheel spin.
  final DateTime? lastAdSpinDate;

  /// Number of rewarded ad spins used today.
  final int adSpinsUsedToday;

  /// List of furniture item IDs owned in kids room.
  final List<String> kidsOwnedFurniture;

  /// Equipped furniture mapping in kids room.
  final Map<String, String> kidsEquippedFurniture;

  /// Count of golden keys owned.
  final int keys;

  /// Previous leaderboard rank.
  final int? previousRank;

  // ---------------------------------------------------------------------------
  // Kids Room — Buddy Lifecycle (persisted)
  // ---------------------------------------------------------------------------
  /// Current emotional state of the kids buddy companion.
  final String kidsBuddyMood; // happy, hungry, sleepy, bored

  /// Energy percentage of the kids buddy companion (0-100).
  final int kidsBuddyEnergy; // 0-100

  /// Hunger percentage of the kids buddy companion (0-100).
  final int kidsBuddyHunger; // 0-100

  /// Timestamp of the last care interaction with the kids buddy.
  final DateTime? kidsLastCareDate;

  /// Consecutive day streak of caring for the kids buddy.
  final int kidsCareStreak;

  /// Room progression level in kids zone.
  final int kidsRoomLevel;

  /// Theme key for the kids room environment.
  final String kidsRoomTheme; // nature, space, ocean, sweet

  /// Timestamp when the kids buddy was last fed.
  final DateTime? kidsLastFeedTime;

  /// Number of minigames played in kids zone today.
  final int kidsGamesPlayedToday;

  /// Timestamp of the most recent kids game played.
  final DateTime? kidsLastGameDate;

  /// Creates a [UserEntity] instance.
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
    // Single source of truth via UserGameConstants — no more inline duplication.
    this.unlockedLevels = UserGameConstants.kDefaultUnlockedLevels,
    this.completedLevels = const {},
    this.starRatings = const {},
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
    this.kidsOwnedFurniture = UserGameConstants.kDefaultKidsOwnedFurniture,
    this.kidsEquippedFurniture =
        UserGameConstants.kDefaultKidsEquippedFurniture,
    this.kidsCoins = 0,
    this.kidsStickers = const [],
    this.kidsMascot,
    this.kidsEquippedSticker,
    this.kidsOwnedAccessories = const [],
    this.kidsEquippedAccessory,
    this.vowlMascot,
    this.vowlEquippedAccessory,
    this.vowlOwnedAccessories = const [],
    this.vowlOwnedMascots = UserGameConstants.kDefaultVowlOwnedMascots,
    this.claimedStreakMilestones = const [],
    this.claimedLevelMilestones = const [],
    this.coinHistory = const [],
    this.hasPermanentXPBoost = false,
    this.lastFreeSpinDate,
    this.lastAdSpinDate,
    this.adSpinsUsedToday = 0,
    this.keys = 0,
    this.previousRank,
    this.kidsBuddyMood = 'happy',
    this.kidsBuddyEnergy = 100,
    this.kidsBuddyHunger = 0,
    this.kidsLastCareDate,
    this.kidsCareStreak = 0,
    this.kidsRoomLevel = 1,
    this.kidsRoomTheme = 'nature',
    this.kidsLastFeedTime,
    this.kidsGamesPlayedToday = 0,
    this.kidsLastGameDate,
  });

  // ---------------------------------------------------------------------------
  // Derived getters
  // ---------------------------------------------------------------------------

  /// Current user level derived from total XP.
  int get level => (totalExp / UserGameConstants.kXpPerLevel).floor() + 1;

  /// Total number of individual game levels completed across all adult categories.
  int get totalLevelsCompleted {
    var count = 0;
    for (final levels in completedLevels.values) {
      count += levels.length;
    }
    return count - kidsTotalLevelsCompleted;
  }

  /// Whether this account is exclusively used for Kids mode.
  /// Used to hide complex analytical features like Review Mistakes.
  bool get isKidsModeOnly => totalExp == 0 && kidsTotalLevelsCompleted > 0;

  /// Total number of kids game levels completed.
  int get kidsTotalLevelsCompleted {
    final adultCategories = QuestType.values
        .expand((q) => [q.name, q.serializedName])
        .toSet();
    adultCategories.addAll(GameSubtype.values.map((s) => s.name));
    // Exclude standard non-kids core systems just in case
    adultCategories.addAll([
      'diagnostic',
      'placement',
      'placement_test',
      'daily_challenge',
    ]);

    var count = 0;
    for (final entry in completedLevels.entries) {
      if (!adultCategories.contains(entry.key)) {
        count += entry.value.length;
      }
    }
    return count;
  }

  /// Whether the Double XP power-up is currently active.
  bool get isDoubleXPActive {
    if (doubleXPExpiry == null) return false;
    return doubleXPExpiry!.isAfter(DateTime.now());
  }

  /// Whether the user is eligible to claim today's VIP gift.
  bool get isVipGiftAvailable {
    if (!isPremium) return false;
    if (lastVipGiftDate == null) return true;
    final now = DateTime.now();
    final last = lastVipGiftDate!;
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  // ---------------------------------------------------------------------------
  // Mastery getters (delegates to QuestType subtypes)
  // ---------------------------------------------------------------------------

  List<String> get earnedBadges => badges;

  int get speakingMastery => getCategoryProgress(QuestType.speaking);
  int get readingMastery => getCategoryProgress(QuestType.reading);
  int get writingMastery => getCategoryProgress(QuestType.writing);
  int get vocabularyMastery => getCategoryProgress(QuestType.vocabulary);
  int get grammarMastery => getCategoryProgress(QuestType.grammar);
  int get listeningMastery => getCategoryProgress(QuestType.listening);
  int get accentMastery => getCategoryProgress(QuestType.accent);
  int get roleplayMastery => getCategoryProgress(QuestType.roleplay);

  /// Returns the highest [categoryStats] score across all non-legacy subtypes
  /// of [type]. Returns 0 if the type has no tracked subtypes.
  int getCategoryProgress(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    if (subtypes.isEmpty) return 0;
    var maxProgress = 0;
    for (final subtype in subtypes) {
      final progress = categoryStats[subtype.name] ?? 0;
      if (progress > maxProgress) maxProgress = progress;
    }
    return maxProgress;
  }

  /// Returns the total number of levels cleared across all non-legacy subtypes
  /// of [type] (i.e., sum of completed levels arrays for each subtype).
  int getTotalCategoryLevelsCleared(QuestType type) {
    final subtypes = type.subtypes.where((s) => !s.isLegacy).toList();
    var totalCleared = 0;
    for (final subtype in subtypes) {
      totalCleared += completedLevels[subtype.name]?.length ?? 0;
    }
    return totalCleared;
  }

  /// Returns the theoretical maximum levels available for [type]
  /// (200 levels × number of non-legacy subtypes).
  int getMaxCategoryLevels(QuestType type) {
    return type.subtypes.where((s) => !s.isLegacy).length * 200;
  }

  /// Maps a raw level index to its effective (display) level, wrapping levels
  /// above 200 into a 150–199 repeating range.
  ///
  /// NOTE: [categoryOrGame] is intentionally accepted but not currently used
  /// in the wrap calculation — every category wraps identically today. It is
  /// kept in the signature (rather than removed) because removing a public
  /// parameter would be a breaking change for every call site across the app,
  /// which is outside the visibility of this review. If a future requirement
  /// needs per-category wrap thresholds, this is where that branch belongs;
  /// if it's confirmed nothing will ever need that, this parameter is safe to
  /// delete in a dedicated follow-up that also updates all call sites.
  int getEffectiveLevel(String categoryOrGame, int level) {
    if (level <= 200) return level;
    return 150 + ((level - 201) % 50);
  }

  /// Returns a clean, production-grade display name.
  /// If [displayName] is null, empty, or a legacy sentinel like "Unknown User",
  /// it gracefully derives a formatted name from [email] (capitalized) or returns [fallback].
  String getSafeDisplayName({String fallback = 'Vowl Learner'}) {
    final name = displayName?.trim();
    if (name != null &&
        name.isNotEmpty &&
        name.toLowerCase() != 'unknown user' &&
        name.toLowerCase() != 'unknown') {
      return name;
    }
    if (email.isNotEmpty && email.contains('@')) {
      final prefix = email.split('@').first.replaceAll(RegExp(r'[._\-+0-9]+'), ' ').trim();
      if (prefix.isNotEmpty) {
        return prefix
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
            .join(' ');
      }
      final rawPrefix = email.split('@').first.trim();
      if (rawPrefix.isNotEmpty) {
        return rawPrefix[0].toUpperCase() + rawPrefix.substring(1);
      }
    }
    return fallback;
  }

  /// Convenience getter returning [getSafeDisplayName] with the default fallback.
  String get safeDisplayName => getSafeDisplayName();

  // ---------------------------------------------------------------------------
  // copyWith — supports explicit null to clear optional fields
  // ---------------------------------------------------------------------------

  // ignore: long-parameter-list
  UserEntity copyWith({
    // Non-nullable fields use standard nullable param (null = keep existing).
    List<String>? badges,
    Map<String, int>? categoryStats,
    List<int>? claimedLevelMilestones,
    List<int>? claimedStreakMilestones,
    List<Map<String, dynamic>>? coinHistory,
    int? coins,
    Map<String, List<int>>? completedLevels,
    Map<String, Map<String, int>>? starRatings,
    int? currentStreak,
    Map<String, int>? dailyXpHistory,
    int? doubleXP,
    int? hintCount,
    int? hintPacks,
    bool? isAdmin,
    bool? isEmailVerified,
    bool? isPremium,
    int? kidsCoins,
    List<String>? kidsOwnedAccessories,
    List<String>? kidsStickers,
    int? streakFreezes,
    int? totalExp,
    Map<String, int>? unlockedLevels,
    bool? hasPermanentXPBoost,
    int? adSpinsUsedToday,
    List<String>? vowlOwnedAccessories,
    List<String>? vowlOwnedMascots,
    List<String>? kidsOwnedFurniture,
    Map<String, String>? kidsEquippedFurniture,
    List<Map<String, dynamic>>? recentActivities,
    int? keys,
    int? previousRank,
    String? kidsBuddyMood,
    int? kidsBuddyEnergy,
    int? kidsBuddyHunger,
    int? kidsCareStreak,
    int? kidsRoomLevel,
    String? kidsRoomTheme,
    int? kidsGamesPlayedToday,

    // Nullable fields use Object? + _absent sentinel so callers can pass null
    // explicitly to clear the value, or omit entirely to preserve existing.
    Object? displayName = _absent,
    Object? photoUrl = _absent,
    Object? fcmToken = _absent,
    Object? lastLoginDate = _absent,
    Object? premiumExpiryDate = _absent,
    Object? doubleXPExpiry = _absent,
    Object? lastVipGiftDate = _absent,
    Object? lastDailyRewardDate = _absent,
    Object? lastKidsDailyRewardDate = _absent,
    Object? kidsMascot = _absent,
    Object? kidsEquippedSticker = _absent,
    Object? kidsEquippedAccessory = _absent,
    Object? vowlMascot = _absent,
    Object? vowlEquippedAccessory = _absent,
    Object? lastFreeSpinDate = _absent,
    Object? lastAdSpinDate = _absent,
    Object? kidsLastCareDate = _absent,
    Object? kidsLastFeedTime = _absent,
    Object? kidsLastGameDate = _absent,
  }) {
    return UserEntity(
      id: id,
      email: email,
      // Non-nullable: standard ?? pattern.
      badges: badges ?? this.badges,
      categoryStats: categoryStats ?? this.categoryStats,
      claimedLevelMilestones:
          claimedLevelMilestones ?? this.claimedLevelMilestones,
      claimedStreakMilestones:
          claimedStreakMilestones ?? this.claimedStreakMilestones,
      coinHistory: coinHistory ?? this.coinHistory,
      coins: coins ?? this.coins,
      completedLevels: completedLevels ?? this.completedLevels,
      starRatings: starRatings ?? this.starRatings,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyXpHistory: dailyXpHistory ?? this.dailyXpHistory,
      doubleXP: doubleXP ?? this.doubleXP,
      hintCount: hintCount ?? this.hintCount,
      hintPacks: hintPacks ?? this.hintPacks,
      isAdmin: isAdmin ?? this.isAdmin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
      kidsCoins: kidsCoins ?? this.kidsCoins,
      kidsOwnedAccessories: kidsOwnedAccessories ?? this.kidsOwnedAccessories,
      kidsStickers: kidsStickers ?? this.kidsStickers,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      totalExp: totalExp ?? this.totalExp,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      hasPermanentXPBoost: hasPermanentXPBoost ?? this.hasPermanentXPBoost,
      adSpinsUsedToday: adSpinsUsedToday ?? this.adSpinsUsedToday,
      vowlOwnedAccessories: vowlOwnedAccessories ?? this.vowlOwnedAccessories,
      vowlOwnedMascots: vowlOwnedMascots ?? this.vowlOwnedMascots,
      kidsOwnedFurniture: kidsOwnedFurniture ?? this.kidsOwnedFurniture,
      kidsEquippedFurniture:
          kidsEquippedFurniture ?? this.kidsEquippedFurniture,
      recentActivities: recentActivities ?? this.recentActivities,
      keys: keys ?? this.keys,
      previousRank: previousRank ?? this.previousRank,
      kidsBuddyMood: kidsBuddyMood ?? this.kidsBuddyMood,
      kidsBuddyEnergy: kidsBuddyEnergy ?? this.kidsBuddyEnergy,
      kidsBuddyHunger: kidsBuddyHunger ?? this.kidsBuddyHunger,
      kidsCareStreak: kidsCareStreak ?? this.kidsCareStreak,
      kidsRoomLevel: kidsRoomLevel ?? this.kidsRoomLevel,
      kidsRoomTheme: kidsRoomTheme ?? this.kidsRoomTheme,
      kidsGamesPlayedToday: kidsGamesPlayedToday ?? this.kidsGamesPlayedToday,
      // Nullable: sentinel pattern — explicit null clears; absent preserves.
      displayName: identical(displayName, _absent)
          ? this.displayName
          : displayName as String?,
      photoUrl: identical(photoUrl, _absent)
          ? this.photoUrl
          : photoUrl as String?,
      fcmToken: identical(fcmToken, _absent)
          ? this.fcmToken
          : fcmToken as String?,
      lastLoginDate: identical(lastLoginDate, _absent)
          ? this.lastLoginDate
          : lastLoginDate as DateTime?,
      premiumExpiryDate: identical(premiumExpiryDate, _absent)
          ? this.premiumExpiryDate
          : premiumExpiryDate as DateTime?,
      doubleXPExpiry: identical(doubleXPExpiry, _absent)
          ? this.doubleXPExpiry
          : doubleXPExpiry as DateTime?,
      lastVipGiftDate: identical(lastVipGiftDate, _absent)
          ? this.lastVipGiftDate
          : lastVipGiftDate as DateTime?,
      lastDailyRewardDate: identical(lastDailyRewardDate, _absent)
          ? this.lastDailyRewardDate
          : lastDailyRewardDate as DateTime?,
      lastKidsDailyRewardDate: identical(lastKidsDailyRewardDate, _absent)
          ? this.lastKidsDailyRewardDate
          : lastKidsDailyRewardDate as DateTime?,
      kidsMascot: identical(kidsMascot, _absent)
          ? this.kidsMascot
          : kidsMascot as String?,
      kidsEquippedSticker: identical(kidsEquippedSticker, _absent)
          ? this.kidsEquippedSticker
          : kidsEquippedSticker as String?,
      kidsEquippedAccessory: identical(kidsEquippedAccessory, _absent)
          ? this.kidsEquippedAccessory
          : kidsEquippedAccessory as String?,
      vowlMascot: identical(vowlMascot, _absent)
          ? this.vowlMascot
          : vowlMascot as String?,
      vowlEquippedAccessory: identical(vowlEquippedAccessory, _absent)
          ? this.vowlEquippedAccessory
          : vowlEquippedAccessory as String?,
      lastFreeSpinDate: identical(lastFreeSpinDate, _absent)
          ? this.lastFreeSpinDate
          : lastFreeSpinDate as DateTime?,
      lastAdSpinDate: identical(lastAdSpinDate, _absent)
          ? this.lastAdSpinDate
          : lastAdSpinDate as DateTime?,
      kidsLastCareDate: identical(kidsLastCareDate, _absent)
          ? this.kidsLastCareDate
          : kidsLastCareDate as DateTime?,
      kidsLastFeedTime: identical(kidsLastFeedTime, _absent)
          ? this.kidsLastFeedTime
          : kidsLastFeedTime as DateTime?,
      kidsLastGameDate: identical(kidsLastGameDate, _absent)
          ? this.kidsLastGameDate
          : kidsLastGameDate as DateTime?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserEntity) return false;

    return other.id == id &&
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
        _mapEq.equals(other.categoryStats, categoryStats) &&
        _mapEq.equals(other.unlockedLevels, unlockedLevels) &&
        _deepEq.equals(other.completedLevels, completedLevels) &&
        _deepEq.equals(other.starRatings, starRatings) &&
        _listEq.equals(other.badges, badges) &&
        other.streakFreezes == streakFreezes &&
        other.hintCount == hintCount &&
        other.hintPacks == hintPacks &&
        other.doubleXP == doubleXP &&
        other.doubleXPExpiry == doubleXPExpiry &&
        _mapEq.equals(other.dailyXpHistory, dailyXpHistory) &&
        _deepEq.equals(other.recentActivities, recentActivities) &&
        other.lastVipGiftDate == lastVipGiftDate &&
        other.lastDailyRewardDate == lastDailyRewardDate &&
        other.lastKidsDailyRewardDate == lastKidsDailyRewardDate &&
        other.kidsCoins == kidsCoins &&
        _listEq.equals(other.kidsStickers, kidsStickers) &&
        other.kidsMascot == kidsMascot &&
        other.kidsEquippedSticker == kidsEquippedSticker &&
        _listEq.equals(other.kidsOwnedAccessories, kidsOwnedAccessories) &&
        other.kidsEquippedAccessory == kidsEquippedAccessory &&
        other.vowlMascot == vowlMascot &&
        other.vowlEquippedAccessory == vowlEquippedAccessory &&
        _listEq.equals(other.vowlOwnedAccessories, vowlOwnedAccessories) &&
        _listEq.equals(other.vowlOwnedMascots, vowlOwnedMascots) &&
        _listEq.equals(
          other.claimedStreakMilestones,
          claimedStreakMilestones,
        ) &&
        _listEq.equals(other.claimedLevelMilestones, claimedLevelMilestones) &&
        _deepEq.equals(other.coinHistory, coinHistory) &&
        other.hasPermanentXPBoost == hasPermanentXPBoost &&
        other.lastFreeSpinDate == lastFreeSpinDate &&
        other.lastAdSpinDate == lastAdSpinDate &&
        other.adSpinsUsedToday == adSpinsUsedToday &&
        _listEq.equals(other.kidsOwnedFurniture, kidsOwnedFurniture) &&
        _mapEq.equals(other.kidsEquippedFurniture, kidsEquippedFurniture) &&
        other.keys == keys &&
        other.previousRank == previousRank &&
        other.kidsBuddyMood == kidsBuddyMood &&
        other.kidsBuddyEnergy == kidsBuddyEnergy &&
        other.kidsBuddyHunger == kidsBuddyHunger &&
        other.kidsLastCareDate == kidsLastCareDate &&
        other.kidsCareStreak == kidsCareStreak &&
        other.kidsRoomLevel == kidsRoomLevel &&
        other.kidsRoomTheme == kidsRoomTheme &&
        other.kidsLastFeedTime == kidsLastFeedTime;
  }

  @override
  int get hashCode {
    // Split into groups for readability — Object.hashAll(Iterable) has no
    // argument-count ceiling (unlike the variadic Object.hash(a, b, ...),
    // which is capped at 20), so this chunking is a style choice, not a
    // technical requirement.
    final h1 = Object.hashAll([
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
      _mapEq.hash(categoryStats),
      _mapEq.hash(unlockedLevels),
      _deepEq.hash(completedLevels),
      _deepEq.hash(starRatings),
      _listEq.hash(badges),
      streakFreezes,
      hintCount,
      hintPacks,
    ]);
    final h2 = Object.hashAll([
      doubleXP,
      doubleXPExpiry,
      _mapEq.hash(dailyXpHistory),
      _deepEq.hash(recentActivities),
      lastVipGiftDate,
      lastDailyRewardDate,
      lastKidsDailyRewardDate,
      kidsCoins,
      _listEq.hash(kidsStickers),
      kidsMascot,
      kidsEquippedSticker,
      _listEq.hash(kidsOwnedAccessories),
      kidsEquippedAccessory,
      vowlMascot,
      vowlEquippedAccessory,
      _listEq.hash(vowlOwnedAccessories),
      _listEq.hash(vowlOwnedMascots),
      _listEq.hash(claimedStreakMilestones),
      _listEq.hash(claimedLevelMilestones),
      _deepEq.hash(coinHistory),
    ]);
    final h3 = Object.hashAll([
      hasPermanentXPBoost,
      lastFreeSpinDate,
      lastAdSpinDate,
      adSpinsUsedToday,
      _listEq.hash(kidsOwnedFurniture),
      _mapEq.hash(kidsEquippedFurniture),
      keys,
      previousRank,
      kidsBuddyMood,
      kidsBuddyEnergy,
      kidsBuddyHunger,
      kidsLastCareDate,
      kidsCareStreak,
      kidsRoomLevel,
      kidsRoomTheme,
      kidsLastFeedTime,
    ]);
    return Object.hash(h1, h2, h3);
  }
}
