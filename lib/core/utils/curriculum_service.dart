import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

/// Centralized coordinator that maps dynamic curriculum skill categories,
/// dynamically gating level configurations, and prewarming local asset indexes safely.
class CurriculumService {
  static final Map<String, int> _levelCache = {};
  static final Map<String, Future<int>> _pendingFetches = {};

  /// Returns the cached level count if available, otherwise null.
  static int? getCachedLevels(String gameType) => _levelCache[gameType];

  /// Pre-warms the level counts for a list of game types in the background.
  static void prewarmCache(List<String> gameTypes) {
    for (final type in gameTypes) {
      if (!_levelCache.containsKey(type)) {
        unawaited(getTotalLevels(type)); // Triggers background fetch and cache safely without warnings
      }
    }
  }

  /// Fetches the total number of levels for a specific game type by checking asset existence.
  /// 
  /// Utilizes future-cache mapping to resolve and prevent parallel asset loading race conditions.
  static Future<int> getTotalLevels(String gameType) {
    if (_levelCache.containsKey(gameType)) {
      return Future.value(_levelCache[gameType]!);
    }

    // Return the active pending future if a search is already in progress
    if (_pendingFetches.containsKey(gameType)) {
      return _pendingFetches[gameType]!;
    }

    final future = _fetchTotalLevels(gameType);
    _pendingFetches[gameType] = future;
    return future;
  }

  static Future<int> _fetchTotalLevels(String gameType) async {
    int totalLevels = 0;
    int batchIndex = 1;
    bool moreBatches = true;

    try {
      while (moreBatches && batchIndex <= 20) { // Safety cap at 200 levels
        final start = (batchIndex - 1) * 10 + 1;
        final path = QuestRegistry.getAssetPath(gameType, start);
        
        try {
          await rootBundle.load(path);
          totalLevels += 10;
          batchIndex++;
        } catch (e) {
          moreBatches = false;
        }
      }
      
      final finalCount = totalLevels > 0 ? totalLevels : 10;
      _levelCache[gameType] = finalCount;
      if (kDebugMode) {
        debugPrint('CurriculumService: Resolved level boundary for "$gameType" as $finalCount levels.');
      }
      return finalCount;
    } finally {
      _pendingFetches.remove(gameType);
    }
  }
}
