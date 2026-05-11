import 'package:flutter/services.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

class CurriculumService {
  static final Map<String, int> _levelCache = {};

  /// Returns the cached level count if available, otherwise null.
  static int? getCachedLevels(String gameType) => _levelCache[gameType];

  /// Pre-warms the level counts for a list of game types in the background.
  static void prewarmCache(List<String> gameTypes) {
    for (final type in gameTypes) {
      if (!_levelCache.containsKey(type)) {
        getTotalLevels(type); // Triggers background fetch and cache
      }
    }
  }

  /// Fetches the total number of levels for a specific game type by checking asset existence.
  static Future<int> getTotalLevels(String gameType) async {
    if (_levelCache.containsKey(gameType)) {
      return _levelCache[gameType]!;
    }

    int totalLevels = 0;
    int batchIndex = 1;
    bool moreBatches = true;

    while (moreBatches && batchIndex <= 10) { // Safety cap at 100 levels for now
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
    return finalCount;
  }
}
