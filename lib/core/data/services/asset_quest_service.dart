import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voxai_quest/core/data/constants/quest_registry.dart';

class AssetQuestService {
  final Map<String, List<Map<String, dynamic>>> _batchCache = {};

  /// Loads quests for a specific game and level from local assets.
  /// Returns a list of quest maps or an empty list if not found.
  Future<List<Map<String, dynamic>>> getQuests(
    String gameType,
    int level,
  ) async {
    try {
      final path = QuestRegistry.getAssetPath(gameType, level);

      // Return from cache if already loaded
      if (_batchCache.containsKey(path)) {
        return _filterQuests(gameType, level, _batchCache[path]!);
      }

      // Load new batch
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey('quests') && data['quests'] is List) {
        final quests = List<Map<String, dynamic>>.from(data['quests']);

        // Cache the entire batch
        _batchCache[path] = quests;

        return _filterQuests(gameType, level, quests);
      }

      return [];
    } catch (e) {
      debugPrint('AssetQuestService Error: $e');
      return [];
    }
  }

  /// Pre-loads a batch for the next set of levels.
  Future<void> preloadBatch(String gameType, int currentLevel) async {
    try {
      // If we are at level 9, we want to preload the batch for level 11.
      // Batch files are typically 1-10, 11-20, etc.
      // So at level 9, current batch is 1-10. Next batch starts at 11.
      final nextBatchLevel = ((currentLevel + 1) / 10).ceil() * 10 + 1;

      final path = QuestRegistry.getAssetPath(gameType, nextBatchLevel);
      if (_batchCache.containsKey(path)) return;

      debugPrint('AssetQuestService: Pre-loading next batch from $path');
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey('quests') && data['quests'] is List) {
        final quests = List<Map<String, dynamic>>.from(data['quests']);
        _batchCache[path] = quests;
      }
    } catch (e) {
      // Silently fail for pre-loading
    }
  }

  List<Map<String, dynamic>> _filterQuests(
    String gameType,
    int level,
    List<Map<String, dynamic>> quests,
  ) {
    // Regex matches _L1_, _l01_, _L001_, etc.
    // Case-insensitive, handles optional leading zeros, ensures no trailing digits.
    // Robust lookahead and lookbehind to ensure we match the full level number.
    final levelRegex = RegExp('(?<=_l)0*$level(?![0-9])', caseSensitive: false);

    final filtered = quests.where((q) {
      final id = q['id'] as String? ?? '';
      return levelRegex.hasMatch(id);
    }).toList();

    debugPrint(
      'AssetQuestService: Filtered ${filtered.length} quests for level $level',
    );
    return filtered;
  }

  /// Clears the memory cache.
  void clearCache() {
    debugPrint('AssetQuestService: Clearing batch cache');
    _batchCache.clear();
  }
}
