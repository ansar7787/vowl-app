import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

/// Centralised coordinator that maps dynamic curriculum skill categories,
/// gates level configurations, and pre-warms local asset indices safely.
///
/// ### Caching strategy
/// Level counts are cached in a static Map so that multiple service
/// instances (e.g., in tests) share the same results and avoid redundant
/// asset probes. The cache can be cleared via [clearCache] for test isolation.
///
/// ### Testability
/// FIX (MEDIUM-4): Previously `_levelCache` and `_pendingFetches` were private
/// static fields with no way to reset them between tests. Static state that
/// persists across test runs causes order-dependent failures. [clearCache]
/// provides a clean reset point.
class CurriculumService {
  CurriculumService._(); // Non-instantiable utility class.

  // ── Cache ─────────────────────────────────────────────────────────────────

  /// Resolved level counts keyed by game-type string.
  @visibleForTesting
  static final Map<String, int> levelCache = {};

  /// In-flight fetch futures — deduplicate parallel calls for the same type.
  static final Map<String, Future<int>> _pendingFetches = {};

  /// Clears all cached results. Call in test [setUp] or [tearDown] to prevent
  /// cross-test pollution.
  static void clearCache() {
    levelCache.clear();
    _pendingFetches.clear();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the cached level count for [gameType], or `null` if not yet
  /// resolved. Does not trigger a fetch.
  static int? getCachedLevels(String gameType) => levelCache[gameType];

  /// Pre-warms the level count cache for a list of game types in the
  /// background. Safe to call during app startup — completions are ignored.
  static void prewarmCache(List<String> gameTypes) {
    unawaited(_prewarmCacheFromManifest(gameTypes));
  }

  static Future<void> _prewarmCacheFromManifest(List<String> gameTypes) async {
    try {
      // 1. Load the manifest using the official future-proof API (handles .json or .bin natively).
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );

      // Convert to Set for O(1) lookups in memory.
      final Set<String> manifestPaths = manifest.listAssets().toSet();

      // 2. Loop through games and count levels instantly in RAM.
      for (final type in gameTypes) {
        if (!levelCache.containsKey(type)) {
          int totalLevels = 0;
          int batchIndex = 1;

          while (batchIndex <= 20) {
            final start = (batchIndex - 1) * 10 + 1;
            final path = QuestRegistry.getAssetPath(type, start);

            if (manifestPaths.contains(path)) {
              totalLevels += 10;
              batchIndex++;
            } else {
              break;
            }
          }

          final finalCount = totalLevels > 0 ? totalLevels : 10;
          levelCache[type] = finalCount;

          if (kDebugMode) {
            debugPrint(
              'CurriculumService: "$type" resolved as $finalCount levels.',
            );
          }
        }
      }
    } catch (e) {
      // Fallback if AssetManifest parsing fails for any reason
      for (final type in gameTypes) {
        if (!levelCache.containsKey(type)) {
          unawaited(getTotalLevels(type));
        }
      }
    }
  }

  /// Returns the total number of available levels for [gameType].
  ///
  /// Results are cached after the first call. Parallel calls for the same
  /// type share a single in-flight future to avoid redundant asset probes.
  static Future<int> getTotalLevels(String gameType) {
    final cached = levelCache[gameType];
    if (cached != null) return Future.value(cached);

    // Return the in-flight future if already resolving.
    return _pendingFetches.putIfAbsent(gameType, () => _fetch(gameType));
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<int> _fetch(String gameType) async {
    int totalLevels = 0;
    int batchIndex = 1;

    try {
      // Safety cap: maximum 20 batches × 10 levels = 200 levels.
      while (batchIndex <= 20) {
        final start = (batchIndex - 1) * 10 + 1;
        final path = QuestRegistry.getAssetPath(gameType, start);

        try {
          await rootBundle.load(path);
          totalLevels += 10;
          batchIndex++;
        } catch (_) {
          // No asset at this batch index — we've found the boundary.
          break;
        }
      }

      // Guarantee at least 10 levels (level 1 is always seeded).
      final finalCount = totalLevels > 0 ? totalLevels : 10;
      levelCache[gameType] = finalCount;

      if (kDebugMode) {
        debugPrint(
          'CurriculumService: "$gameType" resolved as $finalCount levels (Fallback).',
        );
      }

      return finalCount;
    } finally {
      // Always remove from pending so a future retry can enter the fetch path.
      _pendingFetches.remove(gameType);
    }
  }
}
