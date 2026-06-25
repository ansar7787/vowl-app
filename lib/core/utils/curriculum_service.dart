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
    for (final type in gameTypes) {
      if (!levelCache.containsKey(type)) {
        // unawaited: intentional fire-and-forget; suppresses lint warning.
        unawaited(getTotalLevels(type));
      }
    }
  }

  /// Returns the total number of available levels for [gameType].
  ///
  /// Results are cached after the first call. Parallel calls for the same
  /// type share a single in-flight future to avoid redundant asset probes.
  ///
  /// ### Complexity
  /// O(b) asset-bundle `load` calls where b ≤ 20 (safety cap at 200 levels).
  /// Each `load` is a native platform channel call with negligible latency on
  /// modern devices. The result is cached so subsequent calls are O(1).
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
          'CurriculumService: "$gameType" resolved as $finalCount levels.',
        );
      }

      return finalCount;
    } finally {
      // Always remove from pending so a future retry can enter the fetch path.
      _pendingFetches.remove(gameType);
    }
  }
}
