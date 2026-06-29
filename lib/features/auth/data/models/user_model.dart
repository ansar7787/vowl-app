import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

// Reuse the same sentinel definition from user_entity.dart's file scope.
// Since each file is its own compilation unit in Dart, we redeclare a
// functionally-identical sentinel here rather than importing a private symbol.
const _absent = _Absent();

@immutable
final class _Absent {
  const _Absent();
}

/// Concrete data model extending [UserEntity] with Firestore JSON parsing and
/// serialization pipelines.
///
/// ### Parsing
/// [fromMap] implements defensive parsing for every field:
/// - [Timestamp], ISO-8601 [String], and unix epoch [int] are all handled for
///   date fields via [_parseDateTime].
/// - All numeric fields are cast via `(x as num?)?.toInt()` to handle Firestore
///   returning either [int] or [double] depending on the write source.
/// - Nested collections (e.g., [completedLevels]) use explicit element casts
///   to prevent silent `List<dynamic>` type mismatches at call sites.
///
/// ### copyWith
/// Inherits the sentinel-based nullable override from [UserEntity.copyWith],
/// extended here to preserve the concrete [UserModel] return type.
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
    super.starRatings,
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
    super.lastKidsDailyRewardDate,
    super.kidsCoins,
    super.kidsStickers,
    super.kidsMascot,
    super.kidsEquippedSticker,
    super.kidsOwnedAccessories,
    super.kidsEquippedAccessory,
    super.vowlMascot,
    super.vowlEquippedAccessory,
    super.vowlOwnedAccessories,
    super.vowlOwnedMascots,
    super.claimedStreakMilestones,
    super.claimedLevelMilestones,
    super.coinHistory,
    super.hasPermanentXPBoost,
    super.lastFreeSpinDate,
    super.lastAdSpinDate,
    super.adSpinsUsedToday,
    super.kidsOwnedFurniture,
    super.kidsEquippedFurniture,
  });

  // ---------------------------------------------------------------------------
  // Deserialization
  // ---------------------------------------------------------------------------

  /// Deserializes a Firestore document map into a [UserModel].
  ///
  /// Prefer this constructor for Firestore reads. [fromJson] is an alias kept
  /// for backwards compatibility with any REST/cache layer.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      totalExp: (map['totalExp'] as num?)?.toInt() ?? 0,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      lastLoginDate: _parseDateTime(map['lastLoginDate']),
      isEmailVerified: (map['isEmailVerified'] as bool?) ?? false,
      isPremium: (map['isPremium'] as bool?) ?? false,
      premiumExpiryDate: _parseDateTime(map['premiumExpiryDate']),
      categoryStats: _parseIntMap(map['categoryStats']),
      unlockedLevels: map['unlockedLevels'] != null
          ? _parseIntMap(map['unlockedLevels'])
          : UserGameConstants.kDefaultUnlockedLevels,
      completedLevels: _parseCompletedLevels(map['completedLevels']),
      starRatings: _parseStarRatings(map['starRatings']),
      badges: _parseStringList(map['badges']),
      streakFreezes: (map['streakFreezes'] as num?)?.toInt() ?? 0,
      hintCount: (map['hintCount'] as num?)?.toInt() ?? 0,
      hintPacks: (map['hintPacks'] as num?)?.toInt() ?? 0,
      doubleXP: (map['doubleXP'] as num?)?.toInt() ?? 0,
      doubleXPExpiry: _parseDateTime(map['doubleXPExpiry']),
      dailyXpHistory: _parseIntMap(map['dailyXpHistory']),
      recentActivities: _parseDynamicMapList(map['recentActivities']),
      lastVipGiftDate: _parseDateTime(map['lastVipGiftDate']),
      lastDailyRewardDate: _parseDateTime(map['lastDailyRewardDate']),
      lastKidsDailyRewardDate: _parseDateTime(map['lastKidsDailyRewardDate']),
      kidsCoins: (map['kidsCoins'] as num?)?.toInt() ?? 0,
      kidsStickers: _parseStringList(map['kidsStickers']),
      kidsMascot: map['kidsMascot'] as String?,
      kidsEquippedSticker: map['kidsEquippedSticker'] as String?,
      kidsOwnedAccessories: _parseStringList(map['kidsOwnedAccessories']),
      kidsEquippedAccessory: map['kidsEquippedAccessory'] as String?,
      vowlMascot: map['vowlMascot'] as String?,
      vowlEquippedAccessory: map['vowlEquippedAccessory'] as String?,
      vowlOwnedAccessories: _parseStringList(map['vowlOwnedAccessories']),
      vowlOwnedMascots: map['vowlOwnedMascots'] != null
          ? _parseStringList(map['vowlOwnedMascots'])
          : UserGameConstants.kDefaultVowlOwnedMascots,
      claimedStreakMilestones: _parseIntList(map['claimedStreakMilestones']),
      claimedLevelMilestones: _parseIntList(map['claimedLevelMilestones']),
      coinHistory: _parseDynamicMapList(map['coinHistory']),
      hasPermanentXPBoost: (map['hasPermanentXPBoost'] as bool?) ?? false,
      lastFreeSpinDate: _parseDateTime(map['lastFreeSpinDate']),
      lastAdSpinDate: _parseDateTime(map['lastAdSpinDate']),
      adSpinsUsedToday: (map['adSpinsUsedToday'] as num?)?.toInt() ?? 0,
      kidsOwnedFurniture: map['kidsOwnedFurniture'] != null
          ? _parseStringList(map['kidsOwnedFurniture'])
          : UserGameConstants.kDefaultKidsOwnedFurniture,
      kidsEquippedFurniture: map['kidsEquippedFurniture'] != null
          ? Map<String, String>.from(
              map['kidsEquippedFurniture'] as Map<Object?, Object?>,
            )
          : UserGameConstants.kDefaultKidsEquippedFurniture,
    );
  }

  /// Alias for [fromMap] retained for backwards compatibility.
  factory UserModel.fromJson(Map<String, dynamic> map) =>
      UserModel.fromMap(map);

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Serializes this model to a Firestore-compatible map.
  ///
  /// Date fields are always written as [Timestamp] so Firestore can index them.
  /// `null` fields are explicitly written as `null` so that [merge: true] writes
  /// correctly clear previously-set values when the caller passes an updated
  /// entity with a cleared field.
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
      'starRatings': starRatings,
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
      'vowlMascot': vowlMascot,
      'vowlEquippedAccessory': vowlEquippedAccessory,
      'vowlOwnedAccessories': vowlOwnedAccessories,
      'vowlOwnedMascots': vowlOwnedMascots,
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
      'kidsOwnedFurniture': kidsOwnedFurniture,
      'kidsEquippedFurniture': kidsEquippedFurniture,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith — returns concrete UserModel, supports nullable clearing
  // ---------------------------------------------------------------------------

  @override
  UserModel copyWith({
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
    // Nullable sentinel fields
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
      // Sentinel nullable fields
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
    );
  }

  // ---------------------------------------------------------------------------
  // Private parsing helpers
  // ---------------------------------------------------------------------------

  /// Safely parses a date-time value from a Firestore field which may be a
  /// [Timestamp], ISO-8601 [String], unix epoch [int], or null.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    // Last resort: attempt toDate() for legacy Firestore objects.
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  /// Parses a Firestore map of {String → num} to {String → int} defensively.
  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw == null) return const {};
    final map = raw as Map<Object?, Object?>;
    return map.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  /// Parses a Firestore list of strings defensively.
  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List<dynamic>).map((e) => e.toString()).toList();
  }

  /// Parses a Firestore list of integers defensively.
  static List<int> _parseIntList(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List<dynamic>)
        .map((e) => (e as num?)?.toInt() ?? 0)
        .toList();
  }

  /// Parses a Firestore list of dynamic maps defensively.
  static List<Map<String, dynamic>> _parseDynamicMapList(dynamic raw) {
    if (raw == null) return const [];
    return (raw as List<dynamic>)
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Parses the nested [completedLevels] map: `{String → List<int>}`.
  static Map<String, List<int>> _parseCompletedLevels(dynamic raw) {
    if (raw == null) return const {};
    final outer = raw as Map<Object?, Object?>;
    return outer.map((key, value) {
      final levels = (value as List<dynamic>)
          .map((v) => (v as num?)?.toInt() ?? 0)
          .toList();
      return MapEntry(key.toString(), levels);
    });
  }

  /// Parses the nested [starRatings] map: `{String → {String → int}}`.
  static Map<String, Map<String, int>> _parseStarRatings(dynamic raw) {
    if (raw == null) return const {};
    final outer = raw as Map<Object?, Object?>;
    return outer.map((categoryKey, categoryMapRaw) {
      if (categoryMapRaw == null) return MapEntry(categoryKey.toString(), const {});
      final inner = categoryMapRaw as Map<Object?, Object?>;
      final parsedInner = inner.map((levelKey, starsRaw) {
        return MapEntry(levelKey.toString(), (starsRaw as num?)?.toInt() ?? 0);
      });
      return MapEntry(categoryKey.toString(), parsedInner);
    });
  }
}
