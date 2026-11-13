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
  /// Creates a [UserModel] instance.
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
    super.previousStreak,
    super.lastStreakDate,
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
    super.vowlMascot,
    super.vowlEquippedAccessory,
    super.vowlOwnedAccessories,
    super.vowlOwnedMascots,
    super.claimedStreakMilestones,
    super.claimedLevelMilestones,
    super.claimedBadgeRewards,
    super.coinHistory,
    super.hasPermanentXPBoost,
    super.keys,
    super.previousRank,
    super.previousRankWeekKey,
    super.referralCode,
    super.referredBy,
    super.pendingReferralCode,
    super.hasClaimedReferral,
    super.totalReferralsCount,
    super.monthlyReferralsCount,
    super.currentReferralMonthKey,
    super.claimedAmbassadorRewardMonthKeys,
    super.claimedWeeklyRewardWeekKeys,
    super.dailyDuelsPlayedToday,
    super.lastDuelDate,
    super.duelWins,
    super.duelLosses,
  });

  // ---------------------------------------------------------------------------
  // Deserialization
  // ---------------------------------------------------------------------------

  /// Deserializes a Firestore document map into a [UserModel].
  ///
  /// Prefer this constructor for Firestore reads. [fromJson] is an alias kept
  /// for backwards compatibility with any REST/cache layer.
  factory UserModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    final parsedId = (map['id'] as String?)?.trim();
    final effectiveId = (parsedId != null && parsedId.isNotEmpty)
        ? parsedId
        : (documentId?.trim() ?? '');

    final parsedPremiumExpiry = _parseDateTime(map['premiumExpiryDate']);
    final rawIsPremium = (map['isPremium'] as bool?) ?? false;
    final effectiveIsPremium =
        rawIsPremium &&
        (parsedPremiumExpiry == null ||
            parsedPremiumExpiry.isAfter(DateTime.now()));

    return UserModel(
      id: effectiveId,
      email: (map['email'] as String?) ?? '',
      displayName: _sanitizeDisplayName(map['displayName'], map['email']),
      photoUrl: map['photoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      totalExp: (map['totalExp'] as num?)?.toInt() ?? 0,
      isAdmin: (map['isAdmin'] as bool?) ?? false,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      previousStreak: (map['previousStreak'] as num?)?.toInt() ?? 0,
      lastStreakDate: map['lastStreakDate'] as String?,
      lastLoginDate: _parseDateTime(map['lastLoginDate']),
      isEmailVerified: (map['isEmailVerified'] as bool?) ?? false,
      isPremium: effectiveIsPremium,
      premiumExpiryDate: parsedPremiumExpiry,
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
      vowlMascot: map['vowlMascot'] as String?,
      vowlEquippedAccessory: map['vowlEquippedAccessory'] as String?,
      vowlOwnedAccessories: _parseStringList(map['vowlOwnedAccessories']),
      vowlOwnedMascots: map['vowlOwnedMascots'] != null
          ? _parseStringList(map['vowlOwnedMascots'])
          : UserGameConstants.kDefaultVowlOwnedMascots,
      claimedStreakMilestones: _parseIntList(map['claimedStreakMilestones']),
      claimedLevelMilestones: _parseIntList(map['claimedLevelMilestones']),
      claimedBadgeRewards: _parseStringList(map['claimedBadgeRewards']),
      coinHistory: _parseDynamicMapList(map['coinHistory']),
      hasPermanentXPBoost: (map['hasPermanentXPBoost'] as bool?) ?? false,
      keys: (map['keys'] as num?)?.toInt() ?? 0,
      previousRank: (map['previousRank'] as num?)?.toInt(),
      previousRankWeekKey: map['previousRankWeekKey'] as String?,
      referralCode: map['referralCode'] as String?,
      referredBy: map['referredBy'] as String?,
      pendingReferralCode: map['pendingReferralCode'] as String?,
      hasClaimedReferral: (map['hasClaimedReferral'] as bool?) ?? false,
      totalReferralsCount: (map['totalReferralsCount'] as num?)?.toInt() ?? 0,
      monthlyReferralsCount:
          (map['monthlyReferralsCount'] as num?)?.toInt() ?? 0,
      currentReferralMonthKey: map['currentReferralMonthKey'] as String?,
      claimedAmbassadorRewardMonthKeys: _parseStringList(
        map['claimedAmbassadorRewardMonthKeys'],
      ),
      claimedWeeklyRewardWeekKeys: _parseStringList(
        map['claimedWeeklyRewardWeekKeys'],
      ),
      dailyDuelsPlayedToday:
          (map['dailyDuelsPlayedToday'] as num?)?.toInt() ?? 0,
      lastDuelDate: _parseDateTime(map['lastDuelDate']),
      duelWins: (map['duelWins'] as num?)?.toInt() ?? 0,
      duelLosses: (map['duelLosses'] as num?)?.toInt() ?? 0,
    );
  }

  /// Alias for [fromMap] retained for backwards compatibility.
  factory UserModel.fromJson(Map<String, dynamic> map) =>
      UserModel.fromMap(map);

  /// Builds a [UserModel] from an existing [UserEntity], copying every field.
  ///
  /// Use this whenever a domain-layer [UserEntity] (e.g. one built via
  /// [UserEntity.copyWith] in a BLoC, or passed into [UserRepository.updateUser])
  /// needs to be persisted. Centralizing the field-by-field mapping here means
  /// a newly-added field only has to be wired up in one place — the call site
  /// just does `UserModel.fromEntity(entity).toMap()` — instead of every
  /// repository method that needs an entity→model conversion re-listing all
  /// ~48 fields by hand (which is exactly how a future field can silently
  /// fail to persist: added to the entity, forgotten at some scattered call
  /// site).
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      fcmToken: entity.fcmToken,
      coins: entity.coins,
      totalExp: entity.totalExp,
      isAdmin: entity.isAdmin,
      currentStreak: entity.currentStreak,
      previousStreak: entity.previousStreak,
      lastStreakDate: entity.lastStreakDate,
      lastLoginDate: entity.lastLoginDate,
      isEmailVerified: entity.isEmailVerified,
      isPremium: entity.isPremium,
      premiumExpiryDate: entity.premiumExpiryDate,
      categoryStats: entity.categoryStats,
      unlockedLevels: entity.unlockedLevels,
      completedLevels: entity.completedLevels,
      starRatings: entity.starRatings,
      badges: entity.badges,
      streakFreezes: entity.streakFreezes,
      hintCount: entity.hintCount,
      hintPacks: entity.hintPacks,
      doubleXP: entity.doubleXP,
      doubleXPExpiry: entity.doubleXPExpiry,
      dailyXpHistory: entity.dailyXpHistory,
      recentActivities: entity.recentActivities,
      lastVipGiftDate: entity.lastVipGiftDate,
      lastDailyRewardDate: entity.lastDailyRewardDate,
      vowlMascot: entity.vowlMascot,
      vowlEquippedAccessory: entity.vowlEquippedAccessory,
      vowlOwnedAccessories: entity.vowlOwnedAccessories,
      vowlOwnedMascots: entity.vowlOwnedMascots,
      claimedStreakMilestones: entity.claimedStreakMilestones,
      claimedLevelMilestones: entity.claimedLevelMilestones,
      claimedBadgeRewards: entity.claimedBadgeRewards,
      coinHistory: entity.coinHistory,
      hasPermanentXPBoost: entity.hasPermanentXPBoost,
      keys: entity.keys,
      previousRank: entity.previousRank,
      previousRankWeekKey: entity.previousRankWeekKey,
      referralCode: entity.referralCode,
      referredBy: entity.referredBy,
      pendingReferralCode: entity.pendingReferralCode,
      hasClaimedReferral: entity.hasClaimedReferral,
      totalReferralsCount: entity.totalReferralsCount,
      monthlyReferralsCount: entity.monthlyReferralsCount,
      currentReferralMonthKey: entity.currentReferralMonthKey,
      claimedAmbassadorRewardMonthKeys: entity.claimedAmbassadorRewardMonthKeys,
      claimedWeeklyRewardWeekKeys: entity.claimedWeeklyRewardWeekKeys,
      dailyDuelsPlayedToday: entity.dailyDuelsPlayedToday,
      lastDuelDate: entity.lastDuelDate,
      duelWins: entity.duelWins,
      duelLosses: entity.duelLosses,
    );
  }

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
      'previousStreak': previousStreak,
      'lastStreakDate': lastStreakDate,
      'lastLoginDate': lastLoginDate != null
          ? Timestamp.fromDate(lastLoginDate!)
          : null,
      'isEmailVerified': isEmailVerified,
      'isPremium':
          isPremium &&
          (premiumExpiryDate == null ||
              premiumExpiryDate!.isAfter(DateTime.now())),
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
      'vowlMascot': vowlMascot,
      'vowlEquippedAccessory': vowlEquippedAccessory,
      'vowlOwnedAccessories': vowlOwnedAccessories,
      'vowlOwnedMascots': vowlOwnedMascots,
      'claimedStreakMilestones': claimedStreakMilestones,
      'claimedLevelMilestones': claimedLevelMilestones,
      'claimedBadgeRewards': claimedBadgeRewards,
      'coinHistory': coinHistory,
      'hasPermanentXPBoost': hasPermanentXPBoost,
      'keys': keys,
      'previousRank': previousRank,
      'previousRankWeekKey': previousRankWeekKey,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'pendingReferralCode': pendingReferralCode,
      'hasClaimedReferral': hasClaimedReferral,
      'totalReferralsCount': totalReferralsCount,
      'monthlyReferralsCount': monthlyReferralsCount,
      'currentReferralMonthKey': currentReferralMonthKey,
      'claimedAmbassadorRewardMonthKeys': claimedAmbassadorRewardMonthKeys,
      'claimedWeeklyRewardWeekKeys': claimedWeeklyRewardWeekKeys,
      'dailyDuelsPlayedToday': dailyDuelsPlayedToday,
      'lastDuelDate': lastDuelDate != null
          ? Timestamp.fromDate(lastDuelDate!)
          : null,
      'duelWins': duelWins,
      'duelLosses': duelLosses,
    };
  }

  /// Serializes this model to a JSON-compatible map for local offline caching.
  /// Recursively converts all [Timestamp] instances to ISO-8601 strings so [jsonEncode] succeeds.
  Map<String, dynamic> toJsonMap() {
    dynamic sanitize(dynamic value) {
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      } else if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), sanitize(v)));
      } else if (value is List) {
        return value.map((e) => sanitize(e)).toList();
      }
      return value;
    }

    final map = toMap();
    return sanitize(map) as Map<String, dynamic>;
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
    List<String>? claimedBadgeRewards,
    List<Map<String, dynamic>>? coinHistory,
    int? coins,
    Map<String, List<int>>? completedLevels,
    Map<String, Map<String, int>>? starRatings,
    int? currentStreak,
    int? previousStreak,
    Map<String, int>? dailyXpHistory,
    int? doubleXP,
    int? hintCount,
    int? hintPacks,
    bool? isAdmin,
    bool? isEmailVerified,
    bool? isPremium,
    int? streakFreezes,
    int? totalExp,
    Map<String, int>? unlockedLevels,
    bool? hasPermanentXPBoost,
    List<String>? vowlOwnedAccessories,
    List<String>? vowlOwnedMascots,
    List<Map<String, dynamic>>? recentActivities,
    int? keys,
    int? previousRank,
    String? previousRankWeekKey,
    bool? hasClaimedReferral,
    int? totalReferralsCount,
    int? monthlyReferralsCount,
    List<String>? claimedAmbassadorRewardMonthKeys,
    List<String>? claimedWeeklyRewardWeekKeys,
    int? dailyDuelsPlayedToday,
    int? duelWins,
    int? duelLosses,
    // Nullable sentinel fields
    Object? displayName = _absent,
    Object? photoUrl = _absent,
    Object? fcmToken = _absent,
    Object? lastLoginDate = _absent,
    Object? lastStreakDate = _absent,
    Object? premiumExpiryDate = _absent,
    Object? doubleXPExpiry = _absent,
    Object? lastVipGiftDate = _absent,
    Object? lastDailyRewardDate = _absent,
    Object? vowlMascot = _absent,
    Object? vowlEquippedAccessory = _absent,
    Object? referralCode = _absent,
    Object? referredBy = _absent,
    Object? pendingReferralCode = _absent,
    Object? currentReferralMonthKey = _absent,
    Object? lastDuelDate = _absent,
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
      claimedBadgeRewards: claimedBadgeRewards ?? this.claimedBadgeRewards,
      coinHistory: coinHistory ?? this.coinHistory,
      coins: coins ?? this.coins,
      completedLevels: completedLevels ?? this.completedLevels,
      starRatings: starRatings ?? this.starRatings,
      currentStreak: currentStreak ?? this.currentStreak,
      previousStreak: previousStreak ?? this.previousStreak,
      dailyXpHistory: dailyXpHistory ?? this.dailyXpHistory,
      doubleXP: doubleXP ?? this.doubleXP,
      hintCount: hintCount ?? this.hintCount,
      hintPacks: hintPacks ?? this.hintPacks,
      isAdmin: isAdmin ?? this.isAdmin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      totalExp: totalExp ?? this.totalExp,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      hasPermanentXPBoost: hasPermanentXPBoost ?? this.hasPermanentXPBoost,
      vowlOwnedAccessories: vowlOwnedAccessories ?? this.vowlOwnedAccessories,
      vowlOwnedMascots: vowlOwnedMascots ?? this.vowlOwnedMascots,
      recentActivities: recentActivities ?? this.recentActivities,
      keys: keys ?? this.keys,
      previousRank: previousRank ?? this.previousRank,
      previousRankWeekKey: previousRankWeekKey ?? this.previousRankWeekKey,
      hasClaimedReferral: hasClaimedReferral ?? this.hasClaimedReferral,
      totalReferralsCount: totalReferralsCount ?? this.totalReferralsCount,
      monthlyReferralsCount:
          monthlyReferralsCount ?? this.monthlyReferralsCount,
      claimedAmbassadorRewardMonthKeys:
          claimedAmbassadorRewardMonthKeys ??
          this.claimedAmbassadorRewardMonthKeys,
      claimedWeeklyRewardWeekKeys:
          claimedWeeklyRewardWeekKeys ?? this.claimedWeeklyRewardWeekKeys,
      dailyDuelsPlayedToday:
          dailyDuelsPlayedToday ?? this.dailyDuelsPlayedToday,
      duelWins: duelWins ?? this.duelWins,
      duelLosses: duelLosses ?? this.duelLosses,
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
      lastStreakDate: identical(lastStreakDate, _absent)
          ? this.lastStreakDate
          : lastStreakDate as String?,
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
      vowlMascot: identical(vowlMascot, _absent)
          ? this.vowlMascot
          : vowlMascot as String?,
      vowlEquippedAccessory: identical(vowlEquippedAccessory, _absent)
          ? this.vowlEquippedAccessory
          : vowlEquippedAccessory as String?,
      referralCode: identical(referralCode, _absent)
          ? this.referralCode
          : referralCode as String?,
      referredBy: identical(referredBy, _absent)
          ? this.referredBy
          : referredBy as String?,
      pendingReferralCode: identical(pendingReferralCode, _absent)
          ? this.pendingReferralCode
          : pendingReferralCode as String?,
      currentReferralMonthKey: identical(currentReferralMonthKey, _absent)
          ? this.currentReferralMonthKey
          : currentReferralMonthKey as String?,
      lastDuelDate: identical(lastDuelDate, _absent)
          ? this.lastDuelDate
          : lastDuelDate as DateTime?,
    );
  }

  // ---------------------------------------------------------------------------
  // Private parsing helpers
  // ---------------------------------------------------------------------------

  /// Safely resolves and sanitizes a display name from Firestore data.
  /// Prevents "Unknown User" or empty sentinels from contaminating user profiles.
  /// Derives from email if present, otherwise returns null.
  static String? _sanitizeDisplayName(dynamic rawName, dynamic rawEmail) {
    if (rawName is String) {
      final trimmed = rawName.trim();
      if (trimmed.isNotEmpty &&
          trimmed.toLowerCase() != 'unknown user' &&
          trimmed.toLowerCase() != 'unknown' &&
          trimmed.toLowerCase() != 'vowl learner') {
        return trimmed;
      }
    }
    if (rawEmail is String && rawEmail.contains('@')) {
      final prefix = rawEmail
          .split('@')
          .first
          .replaceAll(RegExp(r'[._\-+0-9]+'), ' ')
          .trim();
      if (prefix.isNotEmpty) {
        return prefix
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map(
              (w) =>
                  w[0].toUpperCase() +
                  (w.length > 1 ? w.substring(1).toLowerCase() : ''),
            )
            .join(' ');
      }
      final rawPrefix = rawEmail.split('@').first.trim();
      if (rawPrefix.isNotEmpty) {
        return rawPrefix[0].toUpperCase() + rawPrefix.substring(1);
      }
    }
    return null;
  }

  /// Safely parses a date-time value from a Firestore field which may be a
  /// [Timestamp], ISO-8601 [String], unix epoch [int], or null.
  /// Always normalizes to device-local time to prevent calendar day mismatches
  /// when comparing with [DateTime.now()].
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    // Last resort: attempt toDate() for legacy Firestore objects.
    try {
      final dynamic d = value;
      return (d.toDate() as DateTime).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Parses a Firestore map of {String → num} to {String → int} defensively.
  static Map<String, int> _parseIntMap(dynamic raw) {
    if (raw is! Map) return const {};
    final map = raw as Map<Object?, Object?>;
    return map.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }

  /// Parses a Firestore list of strings defensively.
  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  /// Parses a Firestore list of integers defensively.
  static List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => (e as num?)?.toInt() ?? 0).toList();
  }

  /// Parses a Firestore list of dynamic maps defensively.
  static List<Map<String, dynamic>> _parseDynamicMapList(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Parses the nested [completedLevels] map: `{String → List<int>}`.
  static Map<String, List<int>> _parseCompletedLevels(dynamic raw) {
    if (raw is! Map) return const {};
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
    if (raw is! Map) return const {};
    final outer = raw as Map<Object?, Object?>;
    return outer.map((categoryKey, categoryMapRaw) {
      if (categoryMapRaw == null) {
        return MapEntry(categoryKey.toString(), const {});
      }
      final inner = categoryMapRaw as Map<Object?, Object?>;
      final parsedInner = inner.map((levelKey, starsRaw) {
        return MapEntry(levelKey.toString(), (starsRaw as num?)?.toInt() ?? 0);
      });
      return MapEntry(categoryKey.toString(), parsedInner);
    });
  }
}
