import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart';

/// Contract definition for quest-loading service layers.
abstract class QuestService {
  /// Loads quests for a specific game and level from the active source.
  Future<List<Map<String, dynamic>>> getQuests(String gameType, int level);

  /// Pre-loads a batch for the next set of levels in the background.
  Future<void> preloadBatch(String gameType, int currentLevel);

  /// Clears the memory cache.
  void clearCache();
}

/// Parses JSON in an isolate to avoid jank on the main thread.
List<Map<String, dynamic>> _parseQuestsInIsolate(String jsonString) {
  try {
    if (jsonString.trim().isEmpty) return [];
    final Map<String, dynamic> data = jsonDecode(jsonString);
    if (data.containsKey('quests') && data['quests'] is List) {
      return (data['quests'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
  } catch (e) {
    debugPrint(
      'AssetQuestService Isolate Error: Failed to parse JSON. Error: $e',
    );
  }
  return [];
}

/// High-performance local asset quest loader service.
///
/// Employs:
/// 1. **DSA: Least Recently Used (LRU) Cache** via [LinkedHashMap] in $O(1)$ evictions.
/// 2. **DSA: Request Coalescing** via active [Completer] futures to prevent redundant disk reads.
/// 3. **Concurrency: Isolate Parsing** via Flutter's `compute` utility to guarantee 0% UI frame drops.
class AssetQuestService implements QuestService {
  /// Maximum number of batches kept in memory.
  static const int _maxCacheSize = 5;

  /// LRU cache: newest entries at the end, oldest at the front.
  /// Standard DSA lookup and deletion operates in O(1) time complexity.
  final LinkedHashMap<String, List<Map<String, dynamic>>> _batchCache =
      LinkedHashMap();

  /// Coalescing map for active disk loads to prevent simultaneous identical IO tasks.
  final Map<String, Completer<List<Map<String, dynamic>>>> _loadingPaths = {};

  /// Evicts the oldest batch if cache exceeds the limit in O(1) time.
  void _trimCache() {
    while (_batchCache.length > _maxCacheSize) {
      final evicted = _batchCache.keys.first;
      _batchCache.remove(evicted);
      if (kDebugMode) {
        debugPrint('AssetQuestService: Evicted cache for $evicted');
      }
    }
  }

  /// Loads quests for a specific game and level from local assets.
  ///
  /// Returns a list of quest maps or throws a [ServerException] if failed.
  @override
  Future<List<Map<String, dynamic>>> getQuests(
    String gameType,
    int level,
  ) async {
    final path = QuestRegistry.getAssetPath(gameType, level);

    // 1. Return from cache if already loaded (move to end for LRU)
    if (_batchCache.containsKey(path)) {
      final cached = _batchCache.remove(path)!;
      _batchCache[path] = cached;
      return _filterQuests(gameType, level, cached);
    }

    // 2. Return the pending future if already loading (Request Coalescing)
    if (_loadingPaths.containsKey(path)) {
      if (kDebugMode) {
        debugPrint(
          'AssetQuestService: Coalescing request for loading path: $path',
        );
      }
      final quests = await _loadingPaths[path]!.future;
      return _filterQuests(gameType, level, quests);
    }

    final completer = Completer<List<Map<String, dynamic>>>();
    _loadingPaths[path] = completer;
    if (kDebugMode) {
      debugPrint('AssetQuestService: Loading quests from $path');
    }

    try {
      final String jsonString = await rootBundle.loadString(path);
      if (jsonString.isEmpty) {
        throw ServerException('AssetQuestService: JSON file at $path is empty');
      }

      // Concurrency: Parse JSON in a separate isolate to bypass main-thread GC & parsing stutters
      final List<Map<String, dynamic>> quests = await compute(
        _parseQuestsInIsolate,
        jsonString,
      );

      _batchCache[path] = quests;
      _trimCache();
      completer.complete(quests);
      return _filterQuests(gameType, level, quests);
    } catch (e) {
      completer.completeError(e);
      if (e is ServerException) rethrow;
      throw ServerException('AssetQuestService Error loading $path: $e');
    } finally {
      _loadingPaths.remove(path);
    }
  }

  /// Pre-loads a batch for the next set of levels.
  @override
  Future<void> preloadBatch(String gameType, int currentLevel) async {
    // Fast O(1) integer arithmetic without floating-point conversions.
    // currentBatch = which batch currentLevel falls in (1-indexed);
    // nextBatchFirstLevel = the first level of the *following* batch.
    final currentBatch = ((currentLevel - 1) ~/ 10) + 1;
    final nextBatchFirstLevel = currentBatch * 10 + 1;
    final path = QuestRegistry.getAssetPath(gameType, nextBatchFirstLevel);

    if (_batchCache.containsKey(path) || _loadingPaths.containsKey(path)) {
      return;
    }

    try {
      final completer = Completer<List<Map<String, dynamic>>>();
      _loadingPaths[path] = completer;
      if (kDebugMode) {
        debugPrint('AssetQuestService: Pre-loading next batch from $path');
      }

      final String jsonString = await rootBundle.loadString(path);
      final quests = await compute(_parseQuestsInIsolate, jsonString);

      if (quests.isNotEmpty) {
        _batchCache[path] = quests;
        _trimCache();
        completer.complete(quests);
      } else {
        completer.complete([]);
      }
    } catch (e) {
      _loadingPaths[path]?.completeError(e);
      // Silently fail for pre-loading
    } finally {
      _loadingPaths.remove(path);
    }
  }

  List<Map<String, dynamic>> _filterQuests(
    String gameType,
    int level,
    List<Map<String, dynamic>> quests,
  ) {
    final levelStr = level.toString();

    // PERF FIX: these patterns depend only on `level`, not on each quest
    // item, so they must be compiled once per batch (this method call), not
    // once per quest. The previous implementation constructed 2-3 RegExp
    // objects *inside* the per-quest closure, causing O(n) redundant regex
    // compilation for what should be an O(1)-per-item comparison against a
    // pre-built pattern (n = quests per batch, ~30 per file).
    final explicitLevelRegex = RegExp(
      '(?:l|level)0*$levelStr(?![0-9])',
      caseSensitive: false,
    );
    final fallbackRegex = RegExp('(?:^|[^0-9])0*$levelStr(?![0-9])');

    // CORRECTNESS FIX: previously used `id.contains(RegExp('l|level'))` to
    // decide whether an id "uses" explicit level-prefix naming. That pattern
    // is unanchored, so it matches the bare letter 'l' *anywhere* in the id
    // (e.g. "flashcards_5", "collocations_12", "syllableStress_7" all
    // contain an 'l') - which is true for most ids in this dataset. Any id
    // that merely contains the letter 'l' was incorrectly forced onto the
    // strict-only path and, when it didn't match, was silently dropped
    // instead of falling through to the fallback numeric check - causing
    // legitimate quests to vanish from a level and trip the
    // "no quests matched" ServerException below. This anchors the detector
    // to an actual "l123" / "level123"-style token so it only fires for ids
    // that genuinely use that naming convention.
    final usesExplicitLevelPrefix = RegExp(
      r'(?:^|[_-])(?:l|level)0*[0-9]',
      caseSensitive: false,
    );

    bool filterQuests(dynamic q) {
      try {
        // 1. Explicit level field check (Priority)
        final qLevel = q['level'];
        if (qLevel != null && qLevel.toString() == levelStr) {
          return true;
        }

        // 2. ID-based regex check
        final id = q['id']?.toString();
        if (id == null) return false;

        if (usesExplicitLevelPrefix.hasMatch(id)) {
          return explicitLevelRegex.hasMatch(id);
        }

        // 3. Fallback: Check if the ID contains the level number with boundary
        return fallbackRegex.hasMatch(id);
      } catch (e) {
        sl<AppLogger>().error('AssetQuestService: Filter error', error: e);
        return false;
      }
    }

    final filtered = quests.where(filterQuests).toList();

    if (filtered.isEmpty && quests.isNotEmpty) {
      final sampleIds = quests
          .take(5)
          .map((e) => (e['id'] ?? e['questId'] ?? 'no-id').toString())
          .join(', ');
      final message =
          'No quests matched level $level in batch $gameType. Found ${quests.length} quests in file. Sample IDs: $sampleIds.';
      sl<AppLogger>().error(message);
      throw ServerException(message);
    }

    return filtered;
  }

  /// Clears the memory cache.
  @override
  void clearCache() {
    if (kDebugMode) {
      debugPrint('AssetQuestService: Clearing batch cache');
    }
    _batchCache.clear();
  }

  /// Returns the current number of cached batches.
  int get cacheSize => _batchCache.length;
}
