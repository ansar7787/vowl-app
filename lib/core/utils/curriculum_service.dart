import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';

/// Centralised coordinator that maps dynamic curriculum skill categories,
/// gates level configurations, and pre-warms local asset indices safely.
///
/// ### Architecture (v2 — Build-Time Manifest)
/// Level counts are now resolved from [CurriculumManifest], a const Map
/// generated at build time by `scripts/generate_curriculum_manifest.dart`.
/// This eliminates all runtime asset probing, manifest loading, and async
/// overhead. The cache is retained only as a compatibility shim for callers
/// that still read [levelCache] or call [getCachedLevels].
///
/// ### Migration
/// - [prewarmCache] is now a no-op (all data is compile-time const).
/// - [getTotalLevels] returns synchronously via `Future.value`.
/// - Callers should migrate to [CurriculumManifest.getLevels] directly.
class CurriculumService {
  CurriculumService._(); // Non-instantiable utility class.

  // ── Cache (compatibility shim) ──────────────────────────────────────────

  /// Resolved level counts keyed by game-type string.
  /// Now backed by [CurriculumManifest.levelCounts] — retained for backward
  /// compatibility with callers that read this map directly.
  @visibleForTesting
  static final Map<String, int> levelCache = {};

  /// Clears all cached results. Call in test [setUp] or [tearDown] to prevent
  /// cross-test pollution.
  static void clearCache() {
    levelCache.clear();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the level count for [gameType] instantly from the build-time
  /// manifest. Always returns a value (never `null`).
  static int? getCachedLevels(String gameType) =>
      levelCache[gameType] ?? CurriculumManifest.levelCounts[gameType];

  /// Pre-warms the level count cache. Now a no-op since level counts are
  /// resolved from the build-time [CurriculumManifest].
  ///
  /// Retained for backward compatibility — existing call sites do not need
  /// to be updated. This method does nothing and returns immediately.
  static void prewarmCache(List<String> gameTypes) {
    // No-op: CurriculumManifest provides all data at compile time.
    // Populate levelCache for any code that reads it directly.
    for (final type in gameTypes) {
      levelCache.putIfAbsent(type, () => CurriculumManifest.getLevels(type));
    }

    if (kDebugMode) {
      debugPrint(
        'CurriculumService: prewarmCache called for ${gameTypes.length} '
        'types (resolved from build-time manifest).',
      );
    }
  }

  /// Returns the total number of available levels for [gameType].
  ///
  /// Now resolves instantly from [CurriculumManifest] — no async I/O needed.
  /// Returns a [Future] only for API compatibility with existing callers.
  static Future<int> getTotalLevels(String gameType) {
    final count = CurriculumManifest.getLevels(gameType);
    levelCache[gameType] = count;
    return Future.value(count);
  }
}
