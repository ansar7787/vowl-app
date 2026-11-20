import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import '../../presentation/pages/flashcards_learn_fallback_data.dart';

/// Data service dedicated to resolving, parsing, and caching Flashcard curriculum
/// quests for both Learn and Practice phases.
///
/// Ensures the Presentation Layer (UI screens) remains 100% decoupled from
/// asset bundle I/O, file paths, and JSON serialization.
class FlashcardCurriculumService {
  static final FlashcardCurriculumService _instance =
      FlashcardCurriculumService._internal();

  factory FlashcardCurriculumService({AssetBundle? bundle}) {
    if (bundle != null) {
      _instance._bundle = bundle;
    }
    return _instance;
  }

  FlashcardCurriculumService._internal();

  AssetBundle _bundle = rootBundle;

  // In-memory cache to eliminate redundant disk reads when switching screens
  final Map<String, List<PhasedQuest>> _cache = {};

  /// Loads curriculum quests for the Learn phase.
  Future<List<PhasedQuest>> getLearnQuests(int level) async {
    final batchIndex = ((level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final cacheKey = 'learn_${startLevel}_${endLevel}_level_$level';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final path =
          'assets/curriculum/vocabulary/flashcards_learn_${startLevel}_$endLevel.json';
      final jsonStr = await _bundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests.where((q) => q.level == level).toList();
      final result = levelQuests.isNotEmpty ? levelQuests : batch.quests;
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return getFlashcardLearnFallbackQuests(level);
    }
  }

  /// Loads curriculum quests for the Practice phase.
  Future<List<PhasedQuest>> getPracticeQuests(int level) async {
    final batchIndex = ((level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final cacheKey = 'practice_${startLevel}_${endLevel}_level_$level';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final path =
          'assets/curriculum/vocabulary/flashcards_practice_${startLevel}_$endLevel.json';
      final jsonStr = await _bundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests = batch.quests.where((q) => q.level == level).toList();
      final result = levelQuests.isNotEmpty ? levelQuests : batch.quests;
      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return getFlashcardPracticeFallbackQuests(level);
    }
  }

  /// Clears the in-memory curriculum cache (useful for tests or hot reloads).
  void clearCache() {
    _cache.clear();
  }
}
