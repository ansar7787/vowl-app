import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

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
    if (kDebugMode) {
      debugPrint('AssetQuestService Isolate Error: Failed to parse JSON: $e');
    }
  }
  return [];
}

class AssetQuestService {
  /// Maximum number of batches kept in memory.
  /// Each batch is typically 30 quests (~20-50KB), so 5 batches ≈ 250KB max.
  static const int _maxCacheSize = 5;

  /// LRU cache: newest entries at the end, oldest at the front.
  final LinkedHashMap<String, List<Map<String, dynamic>>> _batchCache =
      LinkedHashMap();

  /// Paths currently being loaded to prevent duplicate simultaneous loads.
  final Map<String, Completer<List<Map<String, dynamic>>>> _loadingPaths = {};

  /// Evicts the oldest batch if cache exceeds the limit.
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
  /// Returns a list of quest maps or an empty list if not found.
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

    // 2. Return the pending future if already loading
    if (_loadingPaths.containsKey(path)) {
      debugPrint('AssetQuestService: Waiting for already loading path $path');
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

      final List<Map<String, dynamic>> quests = await compute(_parseQuestsInIsolate, jsonString);

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
  Future<void> preloadBatch(String gameType, int currentLevel) async {
    final nextBatchLevel = ((currentLevel + 1) / 10).ceil() * 10 + 1;
    final path = QuestRegistry.getAssetPath(gameType, nextBatchLevel);
    
    if (_batchCache.containsKey(path) || _loadingPaths.containsKey(path)) return;

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
    // Pattern 2: Generic fallback for other games
    bool filterQuests(dynamic q, int level) {
      try {
        final levelStr = level.toString();
        
        // 1. Explicit level field check (Priority)
        final qLevel = q['level'];
        if (qLevel != null && qLevel.toString() == levelStr) {
          return true;
        }

        // 2. ID-based regex check
        final id = q['id']?.toString();
        if (id == null) return false;

        // Robust Regex for level matching:
        // Matches 'l1', 'level1', 'l01', etc., ensuring boundary protection
        final explicitLevelRegex = RegExp(
          '(?:l|level)0*$levelStr(?![0-9])',
          caseSensitive: false,
        );

        if (id.contains(RegExp('l|level', caseSensitive: false))) {
          return explicitLevelRegex.hasMatch(id);
        }

        // 3. Fallback: Check if the ID ends with or contains the level number with boundary
        // e.g., 'story_1_q1' or 'q1' (if level is 1)
        final fallbackRegex = RegExp(
          '(?:^|[^0-9])0*$levelStr(?![0-9])',
        );
        
        return fallbackRegex.hasMatch(id);
      } catch (e) {
        debugPrint('[AssetQuestService] Filter error: $e');
        return false;
      }
    }

    final filtered = quests.where((q) => filterQuests(q, level)).toList();

    if (filtered.isEmpty && quests.isNotEmpty) {
      final sampleIds = quests.take(5).map((e) => (e['id'] ?? e['questId'] ?? 'no-id').toString()).join(', ');
      final message = 'No quests matched level $level in batch $gameType. Found ${quests.length} quests in file. Sample IDs: $sampleIds.';
      if (kDebugMode) {
        debugPrint('AssetQuestService Error: $message');
      }
      throw ServerException(message);
    }

    return filtered;
  }

  /// Clears the memory cache.
  void clearCache() {
    debugPrint('AssetQuestService: Clearing batch cache');
    _batchCache.clear();
  }

  /// Returns the current number of cached batches.
  int get cacheSize => _batchCache.length;
}

