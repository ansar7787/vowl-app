import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Isolated local data source for Synonym Search Learn & Practice JSON curricula.
///
/// Decouples asset path resolution, raw string loading, and JSON deserialization
/// strictly from presentation screens and widgets.
class SynonymPhaseLocalDataSource {
  final AssetBundle _bundle;

  SynonymPhaseLocalDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  /// Computes the 10-level batch filename prefix (e.g. `1_10`, `11_20`).
  static String batchSuffixForLevel(int level) {
    final safeLevel = level < 1 ? 1 : level;
    final batchStart = ((safeLevel - 1) ~/ 10) * 10 + 1;
    final batchEnd = batchStart + 9;
    return '${batchStart}_$batchEnd';
  }

  static String learnAssetPath(int level) =>
      'assets/curriculum/vocabulary/synonymSearch_learn_${batchSuffixForLevel(level)}.json';

  static String practiceAssetPath(int level) =>
      'assets/curriculum/vocabulary/synonymSearch_practice_${batchSuffixForLevel(level)}.json';

  /// Loads and parses Learn Phase pairs for [level].
  Future<List<SynonymLearnItem>> loadLearnItems(int level) async {
    final rawJson = await _bundle.loadString(learnAssetPath(level));
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final batch = SynonymLearnBatch.fromJson(decoded);
    final items = batch.itemsForLevel(level);
    return items.isNotEmpty ? items : [SynonymLearnItem.fallback(level)];
  }

  /// Loads, parses, and interleaves Practice Phase drills for [level].
  Future<List<SynonymPracticeExercise>> loadPracticeExercises(int level) async {
    final rawJson = await _bundle.loadString(practiceAssetPath(level));
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final batch = SynonymPracticeBatch.fromJson(decoded);
    return batch.buildInterleavedExercisesForLevel(level);
  }
}
