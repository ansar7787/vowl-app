import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Represents a single offline level reward queued for synchronization.
class PendingOfflineReward {
  final String gameType;
  final int level;
  final int xp;
  final int coins;
  final int stars;
  final bool isVaultReward;
  final int? claimChestTier;
  final int? addMagicStars;
  final int timestamp;

  const PendingOfflineReward({
    required this.gameType,
    required this.level,
    required this.xp,
    required this.coins,
    required this.stars,
    this.isVaultReward = false,
    this.claimChestTier,
    this.addMagicStars,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'gameType': gameType,
    'level': level,
    'xp': xp,
    'coins': coins,
    'stars': stars,
    'isVaultReward': isVaultReward,
    if (claimChestTier != null) 'claimChestTier': claimChestTier,
    if (addMagicStars != null) 'addMagicStars': addMagicStars,
    'timestamp': timestamp,
  };

  factory PendingOfflineReward.fromMap(Map<String, dynamic> map) {
    return PendingOfflineReward(
      gameType: map['gameType'] as String? ?? '',
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      stars: (map['stars'] as num?)?.toInt() ?? 3,
      isVaultReward: map['isVaultReward'] as bool? ?? false,
      claimChestTier: (map['claimChestTier'] as num?)?.toInt(),
      addMagicStars: (map['addMagicStars'] as num?)?.toInt(),
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PendingOfflineReward.fromJson(String source) =>
      PendingOfflineReward.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Production-grade service that tracks, persists, and synchronizes offline rewards
/// with Cloud Firestore when network connectivity is restored.
///
/// ### Key Responsibilities:
/// 1. **Persistence**: Queues offline completions in [SharedPreferences] so rewards
///    survive app restarts and process kills.
/// 2. **Reconciliation Protection**: Exposes [totalPendingCoins] and [totalPendingXp]
///    so incoming server snapshots never overwrite uncommitted offline currency.
/// 3. **Rate-Limit Compliance**: Sequentially syncs queued rewards with a safe
///    cooldown delay, fully complying with Firestore Security Rules' 2-second rate limit.
class OfflineRewardSyncService {
  static const String _kPendingRewardsKey = 'vowl_offline_pending_rewards';

  SharedPreferences? _preferences;
  final List<PendingOfflineReward> _pending = [];
  bool _isSyncing = false;
  bool _isInitialized = false;

  OfflineRewardSyncService._();
  static final OfflineRewardSyncService instance = OfflineRewardSyncService._();

  /// Factory constructor for DI or testing with mock preferences.
  factory OfflineRewardSyncService({SharedPreferences? preferences}) {
    if (preferences != null) {
      instance._preferences = preferences;
    }
    return instance;
  }

  /// Initialises local pending queue from disk.
  Future<void> init([SharedPreferences? prefs]) async {
    if (prefs != null) _preferences = prefs;
    _preferences ??= await SharedPreferences.getInstance();
    _loadFromDisk();
    _isInitialized = true;
  }

  void _loadFromDisk() {
    if (_preferences == null) return;
    final rawList = _preferences!.getStringList(_kPendingRewardsKey) ?? [];
    _pending.clear();
    for (final raw in rawList) {
      try {
        _pending.add(PendingOfflineReward.fromJson(raw));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[OfflineRewardSyncService] Parse error for item: $e');
        }
      }
    }
  }

  Future<void> _saveToDisk() async {
    _preferences ??= await SharedPreferences.getInstance();
    final rawList = _pending.map((item) => item.toJson()).toList();
    await _preferences!.setStringList(_kPendingRewardsKey, rawList);
  }

  /// Total coins earned offline that have not yet been confirmed by Firestore.
  int get totalPendingCoins {
    return _pending.fold<int>(0, (sum, item) => sum + item.coins);
  }

  /// Total XP earned offline that has not yet been confirmed by Firestore.
  int get totalPendingXp {
    return _pending.fold<int>(0, (sum, item) => sum + item.xp);
  }

  /// Number of pending offline rewards waiting for synchronization.
  int get pendingCount => _pending.length;

  /// Whether synchronization is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Read-only snapshot of current pending rewards.
  List<PendingOfflineReward> get pendingRewards => List.unmodifiable(_pending);

  /// Records a newly completed level reward earned while offline.
  Future<void> recordPendingReward({
    required String gameType,
    required int level,
    required int xp,
    required int coins,
    required int stars,
    bool isVaultReward = false,
    int? claimChestTier,
    int? addMagicStars,
  }) async {
    if (!_isInitialized) await init();

    // Prevent duplicate entries for normal levels; vault rewards are separate
    if (!isVaultReward) {
      _pending.removeWhere(
        (item) =>
            !item.isVaultReward &&
            item.gameType == gameType &&
            item.level == level,
      );
    }

    _pending.add(
      PendingOfflineReward(
        gameType: gameType,
        level: level,
        xp: xp,
        coins: coins,
        stars: stars,
        isVaultReward: isVaultReward,
        claimChestTier: claimChestTier,
        addMagicStars: addMagicStars,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await _saveToDisk();

    if (kDebugMode) {
      debugPrint(
        '[OfflineRewardSyncService] Queued offline reward: $gameType Lv$level (+$xp XP, +$coins coins). Total pending: ${_pending.length}',
      );
    }
  }

  /// Flushes the pending offline queue to Cloud Firestore sequentially.
  /// Enforces a 2.2-second delay between writes to guarantee compliance with
  /// Firestore Security Rules' 2-second rate-limiting rule.
  Future<void> syncPendingRewards() async {
    if (_isSyncing) return;
    if (!_isInitialized) await init();
    if (_pending.isEmpty) return;

    // Verify network connectivity before starting sync
    if (di.sl.isRegistered<NetworkInfo>() &&
        di.sl<NetworkInfo>().isCurrentlyOffline) {
      if (kDebugMode) {
        debugPrint(
          '[OfflineRewardSyncService] Skipping sync: Device is currently offline.',
        );
      }
      return;
    }

    _isSyncing = true;
    int syncedCount = 0;

    if (kDebugMode) {
      debugPrint(
        '[OfflineRewardSyncService] Starting sync of ${_pending.length} offline rewards...',
      );
    }

    try {
      final queueCopy = List<PendingOfflineReward>.from(_pending);

      for (int i = 0; i < queueCopy.length; i++) {
        final item = queueCopy[i];

        // Double check network before each network roundtrip
        if (di.sl.isRegistered<NetworkInfo>() &&
            di.sl<NetworkInfo>().isCurrentlyOffline) {
          if (kDebugMode) {
            debugPrint(
              '[OfflineRewardSyncService] Network lost during sync. Pausing queue.',
            );
          }
          break;
        }

        if (di.sl.isRegistered<GamificationRepository>()) {
          final repo = di.sl<GamificationRepository>();
          final result = await repo.updateUserRewards(
            gameType: item.gameType,
            level: item.level,
            xpIncrease: item.xp,
            coinIncrease: item.coins,
            starsEarned: item.stars,
            isVaultReward: item.isVaultReward,
            claimChestTier: item.claimChestTier,
            addMagicStars: item.addMagicStars,
          );

          final bool success = result.isRight();
          if (success) {
            _pending.removeWhere(
              (p) =>
                  p.gameType == item.gameType &&
                  p.level == item.level &&
                  p.isVaultReward == item.isVaultReward &&
                  p.claimChestTier == item.claimChestTier,
            );
            await _saveToDisk();
            syncedCount++;

            if (kDebugMode) {
              debugPrint(
                '[OfflineRewardSyncService] Synced: ${item.gameType} Lv${item.level}',
              );
            }

            // Security Rule Anti-Spam protection: Wait 2.2s before the next write
            // if there are more items to commit.
            if (i < queueCopy.length - 1) {
              await Future.delayed(const Duration(milliseconds: 2200));
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                '[OfflineRewardSyncService] Failed to sync ${item.gameType} Lv${item.level}. Will retry on next reconnect.',
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OfflineRewardSyncService] Sync error: $e');
      }
    } finally {
      _isSyncing = false;
      if (syncedCount > 0 && di.sl.isRegistered<AuthBloc>()) {
        di.sl<AuthBloc>().add(const AuthRefreshUser());
      }
    }
  }

  /// Clears the queue in tests or upon explicit account reset.
  Future<void> clearQueue() async {
    _pending.clear();
    await _saveToDisk();
  }
}
